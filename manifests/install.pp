# == Class dcos::install
#
# This class is called from dcos for install
#
class dcos::install {

  $bootstrap_ip=$dcos::bootstrap_ip
  $bootstrap_port=$dcos::bootstrap_port
  $bootstrap_url="http://${bootstrap_ip}:${bootstrap_port}"
  $bootstrap_script=$dcos::bootstrap_script
  $download_dir=$dcos::download_dir
  $download_url = "${bootstrap_url}/${bootstrap_script}"

  exec { 'download bootstrap script':
    command   => "curl -o ${download_dir}/${bootstrap_script} ${download_url}",
    creates   => "${download_dir}/${bootstrap_script}",
    path      => [ '/usr/bin', '/bin', '/usr/sbin', '/sbin', '/opt/puppetlabs/bin/', '/opt/puppetlabs/puppet/bin/' ],
    timeout   => 0,
    tries     => 100000,
    try_sleep => 5,
    logoutput => false,
  }

  -> archive { 'Install cli':
    ensure          => present,
    user            => 'root',
    group           => 'root',
    source          => 'https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.11/dcos',
    path            => '/usr/local/bin/dcos',
    extract         => false,
    cleanup         => false,
    checksum_verify => false,
  }

  -> file { '/usr/local/bin/dcos':
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Archive['Install cli'],
  }

}
