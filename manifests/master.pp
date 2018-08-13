# DC/OS master node
#
class dcos::master {

  $cluster_name       = $dcos::cluster_name
  $bootstrap_ip       = $dcos::bootstrap_ip
  $download_dir       = $dcos::download_dir
  $part               = $dcos::part
  $bootstrap_script   = $dcos::bootstrap_script
  $dcos_admin         = $dcos::dcos_admin
  $dcos_user          = $dcos::dcos_user
  $oauth_enabled      = $dcos::oauth_enabled
  $keep_backup        = $dcos::keep_backup
  $restore_backup     = $dcos::restore_backup
  $nfs_server         = $dcos::nfs_server
  $nfs_dir            = $dcos::nfs_dir
  $manage_adminrouter = $dcos::manage_adminrouter
  $adminrouter        = $dcos::adminrouter
  $mesos              = $dcos::mesos
  $service_name       = $dcos::service_name

  if ($keep_backup == 'nfs') or ($restore_backup == 'nfs') {

    file { '/opt/backups':
      ensure         => 'directory',
    }

    class { '::nfs':
      server_enabled => false,
      client_enabled => true,
      nfs_v4_client  => false,
      require        => File['/opt/backups'],
    }

    nfs::client::mount { '/opt/backups':
      server  => $nfs_server,
      share   => $nfs_dir,
      require => [ File['/opt/backups'], Class['::nfs'] ],
    }
  }

  #add nogroup
  group { 'nogroup':
      ensure => present,
  }

  file { '/root/mesos_role':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $part,
  }

  #changes mode from 0644 to 0755
  file { "${download_dir}/${bootstrap_script}":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Exec['download bootstrap script'],
  }

  exec { 'dcos master install':
    command     => "${download_dir}/${bootstrap_script} master",
    path        => ['/opt/mesosphere/bin', '/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    environment => [
      'LD_LIBRARY_PATH=/opt/mesosphere/lib',
      'PYTHONUNBUFFERED=true',
      'PYTHONPATH=/opt/mesosphere/lib/python3.6/site-packages',
    ],
    onlyif      => 'test -z "`ls -A /opt/mesosphere`"',
    timeout     => 0,
    refreshonly => false,
    logoutput   => true,
    notify      => Exec['check time'],
    require     => [ File["${download_dir}/${bootstrap_script}"], Group['nogroup'] ],
  }

  exec { 'check time':
    command     => '/opt/mesosphere/bin/check-time && date',
    path        => ['/opt/mesosphere/bin', '/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    environment => 'ENABLE_CHECK_TIME=true',
    timeout     => 0,
    refreshonly => true,
    logoutput   => true,
    require     => Exec['dcos master install'],
    tries       => 100,
    try_sleep   => 20,
  }

  if $manage_adminrouter {

    class{'::dcos::adminrouter':
      config  => $adminrouter,
      require => [ Class['dcos::install'], Exec['dcos master install']  ],
    }
  }

  file {'/opt/mesosphere/etc/mesos-master-extras':
    ensure  => 'present',
    content => template('dcos/master-extras.erb'),
    notify  => Service[$service_name],
    require => Exec['dcos master install'],
  }

#  service { $service_name:
#    enable  => true,
#    require => [ File['/opt/mesosphere/etc/mesos-master-extras'], Exec['check time'] ],
#  }

  if ($oauth_enabled == true) {

    if ($facts[dcos_leader] == 'leader') {
      exec { "add dcos admin - ${dcos_admin}":
        command   => "/opt/mesosphere/bin/dcos-shell /opt/mesosphere/bin/dcos_add_user.py ${dcos_admin}",
        path      => [
          '/opt/mesosphere/bin',
          '/opt/mesosphere/active/exhibitor/usr/zookeeper/bin',
          '/bin',
          '/usr/bin',
          '/sbin',
          '/usr/sbin',
        ],
        returns   => 0,
        unless    => "/opt/mesosphere/active/exhibitor/usr/zookeeper/bin/zkCli.sh ls /dcos/users | tail -1 | grep -q ${dcos_admin}",
        require   => Exec['dcos master install'],
        logoutput => true,
      }
    }

    if ($dcos_user) and ($facts[dcos_leader] == 'leader') {
      $dcos_user.each|$user| {
        exec { "add dcos user - ${user}":
          command   => "/opt/mesosphere/bin/dcos-shell /opt/mesosphere/bin/dcos_add_user.py ${user}",
          path      => [
            '/opt/mesosphere/bin',
            '/opt/mesosphere/active/exhibitor/usr/zookeeper/bin',
            '/bin',
            '/usr/bin',
            '/sbin',
            '/usr/sbin',
          ],
          tries     => 7,
          try_sleep => 5,
          returns   => 0,
          unless    => "/opt/mesosphere/active/exhibitor/usr/zookeeper/bin/zkCli.sh ls /dcos/users | tail -1 | grep -q ${user}",
          logoutput => true,
          require   => [Exec["add dcos admin - ${dcos_admin}"], Exec['dcos master install']],
        }
      }
    }
  }

  file { '/var/lib/dcos/exhibitor/zookeeper/snapshot/myid':
    ensure  => 'present',
    owner   => 'dcos_exhibitor',
    group   => 'dcos_exhibitor',
    mode    => '0644',
    content => "${facts['dcos_myid']}\n",
    notify  => Exec['clean zookeeper.out'],
    require => Exec['dcos master install'],
  }

  exec {'clean zookeeper.out':
    command     => 'cat > /var/lib/dcos/exhibitor/zookeeper/zookeeper.out',
    path        => ['/opt/mesosphere/bin', '/opt/mesosphere/active/exhibitor/usr/zookeeper/bin', '/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    require     => File['/var/lib/dcos/exhibitor/zookeeper/snapshot/myid'],
    notify      => Service['dcos-exhibitor'],
    refreshonly => true,
  }

  service { 'dcos-exhibitor':
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
    require    => Exec['clean zookeeper.out'],
  }


  exec { 'check dcos-mesos-master':
    command   => 'systemctl status dcos-mesos-master.service || systemctl restart dcos-mesos-master.service',
    path      => ['/opt/mesosphere/bin', '/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    timeout   => 0,
    tries     => 10,
    try_sleep => 20,
    require   => [
      Service['dcos-exhibitor'],
      Exec['dcos master install'],
      File['/opt/mesosphere/etc/mesos-master-extras'],
      Exec['check time'] ],
  }

  service { 'dcos-mesos-master':
    enable  => true,
    require => [
      Service['dcos-exhibitor'],
      File['/opt/mesosphere/etc/mesos-master-extras'],
      Exec['check time'], Exec['check dcos-mesos-master'] ],
  }
}
