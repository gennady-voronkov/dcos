# This code is to setup a backup cronjob for DCOS zookeeper data
class dcos::backup {
  $application_name = $dcos::application_name
  $application_home = $dcos::application_home
  $cluster_name = $dcos::cluster_name
  $keep_backup = $dcos::keep_backup
  $backup_days = $dcos::backup_days
  $nfs_server = $dcos::nfs_server
  $nfs_dir = $dcos::nfs_dir
  $data_dir = $dcos::data_dir
  $data_log_dir = $dcos::data_log_dir

  file { "/opt/${application_name}":
    ensure => 'directory',
  }

  if ($::dcos_leader == 'leader') {
    $role='leader'
  } else {
      $role='follower'
  }

  if ($keep_backup == 'local') {

    $backup_dir="/var/backups/${application_name}/${cluster_name}"

    file {
      ['/var/backups/',
        "/var/backups/${application_name}",
        "/var/backups/${application_name}/${cluster_name}",
      ]:
        ensure => 'directory',
    }

  } elsif ($keep_backup == 'nfs') {

      $backup_dir="/opt/backups/dcos/${cluster_name}"

      file { ['/opt/backups/dcos', "/opt/backups/dcos/${cluster_name}"]:
        ensure  => 'directory',
        require => Nfs::Client::Mount['/opt/backups'],
      }
  }

  file { "/opt/${application_name}/zookeeper_backup.sh":
    ensure  => file,
    content => template('dcos/zookeeper_backup.erb'),
    owner   => root,
    mode    => '0555',
    require => File["/opt/${application_name}"],
  }

  cron{ 'zookeeper_backup':
    command => "/opt/${application_name}/zookeeper_backup.sh",
    user    => 'root',
    hour    =>'23',
    minute  =>'0',
    require => File["/opt/${application_name}/zookeeper_backup.sh"],
  }
}
