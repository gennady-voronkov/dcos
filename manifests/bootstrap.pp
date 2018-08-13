# == Class dcos::bootstrap
#
# This class is called from dcos for bootstrap.
#
class dcos::bootstrap {

  $cluster_name=$dcos::cluster_name
  $dcos_version=$dcos::dcos_version
  $registry_url=$dcos::registry_url
  $bootstrap_ip=$dcos::bootstrap_ip
  $bootstrap_port=$dcos::bootstrap_port
  $bootstrap_url="http://${bootstrap_ip}:${bootstrap_port}"
  $bootstrap_script=$dcos::bootstrap_script
  $download_dir=$dcos::download_dir
  $master_nodes=$dcos::master_nodes
  $agent_nodes=$dcos::agent_nodes
  $publicagent_nodes=$dcos::publicagent_nodes
  $root_dns=$dcos::root_dns
  $oauth_enabled=$dcos::oauth_enabled
  $sharedfs=$dcos::sharedfs

  file { ['/opt/dcos', '/opt/dcos/genconf', '/mesos_data']:
    ensure => 'directory',
  }

  -> file {'/opt/dcos/genconf/config.yaml':
    ensure  => 'present',
    content => template('dcos/config.yaml.erb'),
    notify  => [Exec['run dcos_generate_config'], Docker::Run['bootstrap_run']],
  }

  -> file {'/opt/dcos/genconf/ip-detect':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/dcos/ip-detect',
  }

  -> file {'/usr/local/bin/dcos-version':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/dcos/dcos-version',
  }

  -> archive { "dcos_generate_config_${dcos_version}.sh":
    ensure          => present,
    allow_insecure  => true,
    checksum_verify => false,
    path            => "/opt/dcos/dcos_generate_config_${dcos_version}.sh",
    source          => "https://downloads.dcos.io/dcos/stable/${dcos_version}/dcos_generate_config.sh",
    cleanup         => false,
    notify          => Exec['run dcos_generate_config'],
  }

  -> file {"/opt/dcos/dcos_generate_config_${dcos_version}.sh":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Archive["dcos_generate_config_${dcos_version}.sh"],
  }

  -> exec { 'run dcos_generate_config':
    command     => "/opt/dcos/dcos_generate_config_${dcos_version}.sh",
    cwd         => '/opt/dcos',
    path        => [ '/usr/bin', '/bin', '/usr/sbin', '/sbin' ],
    timeout     => 0,
    refreshonly => true,
    require     => File["/opt/dcos/dcos_generate_config_${dcos_version}.sh"],
  }

  # docker pull
  docker::image { 'nginx':
    ensure  => 'present',
    require => [ Class['docker'], Archive["dcos_generate_config_${dcos_version}.sh"] ]
  }

  # run docker container with command
  docker::run { 'bootstrap_run':
    image      => 'nginx',
    ports      => "${bootstrap_port}:80",
    net        => 'bridge',
    volumes    => '/opt/dcos/genconf/serve:/usr/share/nginx/html:ro',
    dns        => $root_dns,
    privileged => false,
    require    => [Docker::Image['nginx'], Exec['run dcos_generate_config']],
  }

  if ( $sharedfs == 'nfs' ) {
    class { '::nfs':
      server_enabled => true,
    }

    nfs::server::export { '/mesos_data':
      ensure  => 'mounted',
      #clients => "$::network/$::netmask(rw,insecure,async,no_root_squash) localhost(rw)",
      clients => '*(rw,insecure,async,no_root_squash) localhost(rw)',
    }
  } else {
    notice ('It should be custome shared FS here')
  }

}
