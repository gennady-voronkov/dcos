# == Class dcos::config
#
# This class is called from dcos for service config
#
class dcos::config {

  file_line { 'lc_env_var':
    path => '/etc/environment',
    line => 'LC_ALL=en_US.utf-8',
  }

  file_line { 'lang_env_var':
    path => '/etc/environment',
    line => 'LANG=en_US.utf-8',
  }
}
