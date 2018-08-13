# == Class dcos::params
#
# This class is meant to be called from dcos.
# It sets variables according to platform.
#
class dcos::params {
  $registry_url      = 'https://registry-1.docker.io'
  $bootstrap_script  = 'dcos_install.sh'
  $docker_version    = '17.05.0.ce-1.el7.centos'
  $bootstrap_ip      = undef
  $bootstrap_port    = 9090
  $cluster_name      = undef
  $dcos_admin        = undef
  $dcos_user         = undef
  $dcos_version      = '1.10.4'
  $part              = undef
  $master_nodes      = []
  $agent_nodes       = []
  $publicagent_nodes = []
  $root_dns          = []
  $oauth_enabled     = false
  $sharedfs          = 'local'
  $application_name  = 'zookeeper'
  $application_home  = '/var/lib/dcos/exhibitor/zookeeper'
  $keep_backup       = 'local'
  $restore_backup    = 'local'
  $backup_days       = 3
  $ntp_server        = '0.pool.ntp.org'
  $nfs_server        = undef
  $nfs_dir           = undef
  $data_dir          = 'snapshot'
  $data_log_dir      = 'transactions'
  $download_dir      = '/tmp/dcos'
  $install_checksum  = {
    'hash' => undef,
    'type' => undef,
  }
  $mesos = {}
  $manage_adminrouter = false
  $service_name = 'dcos-mesos-master'
  $adminrouter = {}
  $source_cert_user = undef
  $source_cert_pass = undef
  $executor = {
    'PATH' => '/usr/bin:/bin',
    'SHELL' => '/usr/bin/bash',
    'LIBPROCESS_NUM_WORKER_THREADS' => '8',
    'LD_LIBRARY_PATH' => '/opt/mesosphere/lib',
    'SASL_PATH' => '/opt/mesosphere/lib/sasl2',
  }
}
