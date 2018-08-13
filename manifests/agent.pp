# DC/OS agent node
#
class dcos::agent (
  $public = false,
  $attributes = {},
  $mesos = {},
  $executor = $dcos::params::executor,
) inherits dcos {

  $bootstrap_ip=$dcos::bootstrap_ip
  $bootstrap_port=$dcos::bootstrap_port
  $part=$dcos::part
  $bootstrap_url="http://${bootstrap_ip}:${bootstrap_port}"
  $bootstrap_script=$dcos::bootstrap_script
  $download_dir=$dcos::download_dir
  $sharedfs=$dcos::sharedfs
  $config_dir=$::dcos_config_path

  if $public {
    $dcos_mesos_service = 'dcos-mesos-slave-public'
    $role = 'slave_public'
  } else {
    $dcos_mesos_service = 'dcos-mesos-slave'
    $role = 'slave'
  }

  file { '/root/mesos_role':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $part,
  }

  file { "${download_dir}/${bootstrap_script}":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Exec['download bootstrap script'],
  }

  if $bootstrap_ip {
    exec { 'dcos agent install':
      command     => "${download_dir}/${bootstrap_script} ${role}",
      path        => ['/opt/mesosphere/bin', '/bin', '/usr/bin', '/sbin', '/usr/sbin'],
      environment => [
        'LD_LIBRARY_PATH=/opt/mesosphere/lib',
        'PYTHONUNBUFFERED=true',
        'PYTHONPATH=/opt/mesosphere/lib/python3.6/site-packages',
      ],
      onlyif      => 'test -z "`ls -A /opt/mesosphere`"',
      refreshonly => false,
      logoutput   => true,
      require     => File["${download_dir}/${bootstrap_script}"],
    }
  }


  file {"${config_dir}/etc/mesos-executor-environment.json":
    ensure  => 'present',
    content => dcos_sorted_json($executor),
    notify  => Service[$dcos_mesos_service],
    require => Exec['dcos agent install'],
  }

  file {'/var/lib/dcos':
    ensure => 'directory',
  }

  file_line {'default_tasks_max':
    line => 'DefaultTasksMax=infinity',
    path => '/etc/systemd/system.conf',
  }

  file {'/var/lib/dcos/mesos-slave-common':
    ensure  => 'present',
    content => template('dcos/agent-common.erb'),
    notify  => Service[$dcos_mesos_service],
    require => File['/var/lib/dcos'],
  }

  exec {'stop-dcos-agent':
    command     => "systemctl kill -s SIGUSR1 ${dcos_mesos_service} && systemctl stop ${dcos_mesos_service}",
    path        => '/bin:/usr/bin:/usr/sbin',
    refreshonly => true,
    onlyif      => 'test -d /var/lib/dcos',
    subscribe   => File['/var/lib/dcos/mesos-slave-common'],
    notify      => Exec['dcos-systemd-reload'],
    require     => Exec['dcos agent install'],
  }

  exec { 'dcos-systemd-reload':
    command     => "systemctl daemon-reload && \
                    rm -f /var/lib/mesos/slave/meta/slaves/latest && \
                    sleep 30 && \
                    systemctl start ${dcos_mesos_service}; exit 0",
    path        => '/bin:/usr/bin:/usr/sbin',
    onlyif      => 'test -d /var/lib/dcos',
    refreshonly => true,
    require     => Exec['dcos agent install'],
  }

  service { $dcos_mesos_service:
    ensure  => 'running',
    enable  => true,
    require => Exec['dcos agent install'],
  }

  if ($sharedfs == 'nfs') {
    class { '::nfs':
      client_enabled => true,
      nfs_v4_client  => false,
    }

    nfs::client::mount { '/mesos_data':
      server  => $bootstrap_ip,
      share   => 'mesos_data',
      require => Class['::nfs'],
    }


  } else {
    notice ('It should be custom shared FS')
  }

}
