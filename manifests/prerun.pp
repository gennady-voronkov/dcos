# == Class dcos::prerun
#
# This class is called from dcos for prerun.
#
class dcos::prerun {

  $docker_version=$dcos::docker_version
  $bootstrap_ip=$dcos::bootstrap_ip
  $bootstrap_port=$dcos::bootstrap_port
  $bootstrap_url="http://${bootstrap_ip}:${bootstrap_port}"
  $download_dir=$dcos::download_dir
  $keep_backup = $dcos::keep_backup
  $restore_backup = $dcos::restore_backup
  $root_dns = $dcos::root_dns
  $ntp_server = $dcos::ntp_server
  $nfs_server = $dcos::nfs_server
  $nfs_dir = $dcos::nfs_dir

  file { '/root/check-time':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/dcos/check-time',
  }

  -> exec { 'ntpdate sync':
    command     => "bash -c 'if systemctl status ntpd; then systemctl stop ntpd && ntpdate ${ntp_server}; else ntpdate ${ntp_server}; fi'",
    unless      => '/root/check-time',
    environment => 'ENABLE_CHECK_TIME=true',
    path        => [ '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    timeout     => 0,
  }

  #NTP
  class { '::ntp':
    servers  => [ $ntp_server ],
    restrict => [ '127.0.0.1' ],
    require  => Exec['ntpdate sync'],
  }

  -> exec { 'waiting for sync time':
    command     => '/root/check-time && date',
    path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin'],
    environment => 'ENABLE_CHECK_TIME=true',
    timeout     => 0,
    logoutput   => true,
    require     => Class['::ntp'],
    tries       => 100,
    try_sleep   => 20,
  }

  -> exec { 'check rpmdb':
    command   => 'rm -rf /var/lib/rpm/__db*; rpm --rebuilddb; yum clean all',
    onlyif    => 'test `rpm -qa 1>/dev/null 2>/dev/null;echo $?` -ne 0',
    path      => [ '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    logoutput => true,
    timeout   => 0,
  }

  file { '/root/check_bootstrap.sh':
    ensure  => file,
    content => template('dcos/check_bootstrap.erb'),
    owner   => root,
    mode    => '0555',
  }

  -> package { ['tar', 'xz', 'unzip', 'wget', 'git', 'curl', 'ipset', 'bc', 'nc', 'ipvsadm']:
    ensure  => installed,
    require => Exec['check rpmdb'],
  }

  exec {'update':
    command   => 'yum update -y;echo "do not delete this file">/root/update',
    unless    => 'test -f /root/update',
    path      => [ '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    timeout   => 0,
    logoutput => true,
    require   => Exec['check rpmdb'],
  }

  file { $download_dir:
    ensure => 'directory',
  }

  # UnInstall docker extra
  -> package { ['docker-common', 'docker-selinux']:
    ensure   => purged,
    provider => yum,
    require  => Exec['check rpmdb'],
  }

  -> class { '::docker':
    version        => $docker_version,
    storage_driver => 'overlay',
    require        => Exec['check rpmdb'],
  }

  -> file { '/root/full-uninstall.sh':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('dcos/full-uninstall.erb'),
  }

  -> service { 'rexray':
    ensure => 'stopped',
    enable => false,
  }
}
