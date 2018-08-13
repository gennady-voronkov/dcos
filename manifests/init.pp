# Class: dcos
# ===========================
#
class dcos (
  $cluster_name       = $dcos::params::cluster_name,
  $dcos_version       = $dcos::params::dcos_version,
  $registry_url       = $dcos::params::registry_url,
  $bootstrap_ip       = $dcos::params::bootstrap_ip,
  $bootstrap_port     = $dcos::params::bootstrap_port,
  $bootstrap_script   = $dcos::params::bootstrap_script,
  $docker_version     = $dcos::params::docker_version,
  $part               = $dcos::params::part,
  $download_dir       = $dcos::params::download_dir,
  $install_checksum   = $dcos::params::install_checksum,
  $master_nodes       = $dcos::params::master_nodes,
  $agent_nodes        = $dcos::params::agent_nodes,
  $publicagent_nodes  = $dcos::params::publicagent_nodes,
  $root_dns           = $dcos::params::root_dns,
  $oauth_enabled      = $dcos::params::oauth_enabled,
  $sharedfs           = $dcos::params::sharedfs,
  $dcos_admin         = $dcos::params::dcos_admin,
  $dcos_user          = $dcos::params::dcos_user,
  $ntp_server         = $dcos::params::ntp_server,
  $nfs_server         = $dcos::params::nfs_server,
  $nfs_dir            = $dcos::params::nfs_dir,
  $application_name   = $dcos::params::application_name,
  $application_home   = $dcos::params::application_home,
  $keep_backup        = $dcos::params::keep_backup,
  $restore_backup     = $dcos::params::restore_backup,
  $backup_days        = $dcos::params::backup_days,
  $data_dir           = $dcos::params::data_dir,
  $data_log_dir       = $dcos::params::data_log_dir,
  $mesos              = $dcos::params::mesos,
  $service_name       = $dcos::params::service_name,
  $manage_adminrouter = $dcos::params::manage_adminrouter,
  $adminrouter        = $dcos::params::adminrouter,
  $source_cert_user   = $dcos::params::source_cert_user,
  $source_cert_pass   = $dcos::params::source_cert_pass,
) inherits dcos::params {

  class { '::dcos::prerun': }

  $list_of_int = $facts[interfaces]
  $interfaces = split($list_of_int, ',')

  $interfaces.each | $i | {
    $ipstr = $facts[networking][interfaces][$i][ip]
    if ($bootstrap_ip == $ipstr) {
      class { '::dcos::bootstrap': }
    }
  }

  case $part {
    'master': {
      class { '::dcos::install': }
        -> class { '::dcos::config': }
          -> class { '::dcos::master': }
            -> class { '::dcos::backup': }
              -> class { '::dcos::restore': }
    }
    'slave': {
      class { '::dcos::install': }
        -> class { '::dcos::config': }
          -> class { '::dcos::agent': }
    }
    'slave_public': {
      class { '::dcos::install': }
        -> class { '::dcos::config': }
          -> class { '::dcos::agent': public => true, }
    }
    default: {
      notice ('Nothing to do here')
    }
  }
}
