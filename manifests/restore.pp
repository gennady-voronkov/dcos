# Create .sh script to restore DCOS zookeeper backups
class dcos::restore {
  $application_name = $dcos::application_name
  $application_home = $dcos::application_home
  $cluster_name = $dcos::cluster_name
  $restore_backup = $dcos::restore_backup
  $backup_days = $dcos::backup_days
  $nfs_server = $dcos::nfs_server
  $nfs_dir = $dcos::nfs_dir
  $data_dir = $dcos::data_dir
  $data_log_dir = $dcos::data_log_dir

  if ($::dcos_leader == 'leader') {
    $role='leader'
  } else {
      $role='follower'
  }

  if ($restore_backup == 'local') {
    $backup_dir="/var/backups/${application_name}/${cluster_name}"
  } elsif ($restore_backup == 'nfs') {
    $backup_dir="/opt/backups/dcos/${cluster_name}"
  } else {
      $backup_dir="/var/backups/${application_name}/${cluster_name}"
  }

  file { "/opt/${application_name}/zookeeper_restore.sh":
    ensure  => file,
    content => template('dcos/zookeeper_restore.erb'),
    owner   => root,
    mode    => '0555',
    require => File["/opt/${application_name}"],
  }
}
