# Adminrouter (nginx) config
#
# Config is a hash containing configuration:
#
#  dcos::master::adminrouter:
#    server_name: 'master.example.com'
#    source_cert: 'https://your-host.your-domain.ru/cert'
#

class dcos::adminrouter (
  $config,
) inherits dcos {

  $cluster_name     = $dcos::cluster_name
  $server_name      = pick($config['server_name'], 'master.mesos')
  $source_cert      = pick($config['source_cert'], 'undefine')
  $source_cert_user = $dcos::source_cert_user
  $source_cert_pass = $dcos::source_cert_pass

  file { '/root/cert_dcos':
    ensure  => 'directory',
    require => Exec['dcos master install'],
  }

  if $source_cert == 'undefine' {
    $ssl_certificate = 'includes/snakeoil.crt'
    $ssl_certificate_key = 'includes/snakeoil.key'

  } elsif $source_cert == 'local' {
      $ssl_certificate = "/root/cert_dcos/${cluster_name}.crt"
      $ssl_certificate_key = "/root/cert_dcos/${cluster_name}.key"

    } else {
      $ssl_certificate = "/root/cert_dcos/${cluster_name}.crt"
      $ssl_certificate_key = "/root/cert_dcos/${cluster_name}.key"

      archive { "/root/cert_dcos/${cluster_name}.crt":
        source         => "${source_cert}/${cluster_name}.crt",
        allow_insecure => true,
        username       => $source_cert_user,
        password       => $source_cert_pass,
        notify         => Service['dcos-adminrouter'],
        require        => [ Exec['dcos master install'], File['/root/cert_dcos'] ],
      }

      archive { "/root/cert_dcos/${cluster_name}.key":
        source         => "${source_cert}/${cluster_name}.key",
        allow_insecure => true,
        username       => $source_cert_user,
        password       => $source_cert_pass,
        notify         => Service['dcos-adminrouter'],
        require        => [ Exec['dcos master install'], File['/root/cert_dcos'] ],
      }
  }


  if has_key($config, 'default_scheme') {
    $default_scheme = $config['default_scheme']
  }

  $config_dir = $facts[dcos_config_path]
  $adminrouter_path = $facts[dcos_adminrouter_path]

  if ($config_dir != '' or $config_dir != undef) and ($adminrouter_path != '' or $adminrouter_path != undef) {

    file {"${config_dir}/etc_master/adminrouter-listen-open.conf":
      ensure  => 'present',
      content => template('dcos/adminrouter-listen-open.conf.erb'),
      notify  => Service['dcos-adminrouter'],
#      require  => [ Archive["/root/cert_dcos/${cluster_name}.crt"], Archive["/root/cert_dcos/${cluster_name}.crt"] ],
    }

    file {"${adminrouter_path}/nginx/conf/nginx.master.conf":
      ensure  => 'present',
      content => template('dcos/nginx.master.conf.erb'),
      notify  => Service['dcos-adminrouter'],
#      require  => [ Archive["/root/cert_dcos/${cluster_name}.crt"], Archive["/root/cert_dcos/${cluster_name}.crt"] ],
    }

    file {"${config_dir}/etc/adminrouter.env":
      ensure  => 'present',
      content => template('dcos/adminrouter.env.erb'),
      notify  => Service['dcos-adminrouter'],
#      require  => [ Archive["/root/cert_dcos/${cluster_name}.crt"], Archive["/root/cert_dcos/${cluster_name}.crt"] ],
    }

    service { 'dcos-adminrouter':
      ensure     => 'running',
      hasstatus  => true,
      hasrestart => true,
      enable     => true,
      require    => [
        File["${config_dir}/etc_master/adminrouter-listen-open.conf"],
        File["${adminrouter_path}/nginx/conf/nginx.master.conf"],
      ],
    }
  }
}
