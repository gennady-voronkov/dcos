require 'puppet'
require 'beaker-rspec'
require 'pry'


step "Install Puppet on each host"
install_puppet_agent_on(hosts, { :puppet_collection => 'puppet5' })

UNSUPPORTED_PLATFORMS = ['AIX', 'windows', 'Solaris', 'Suse', 'Ubuntu'].freeze

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'dcos')
    hosts.each do |host|
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-apt'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'stahnma-epel'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-ntp'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'derdanne-nfs'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppet-archive'), { :acceptable_exit_codes => [0,1] }
      on host, puppet('module', 'install', 'puppetlabs-docker'), { :acceptable_exit_codes => [0,1] }
      on host, 'mkdir -p /home/vagrant/.puppetlabs/opt/puppet/cache/facts.d'
      on host, 'mkdir -p /home/vagrant/.puppetlabs/var'
      on host, 'mkdir -p /home/vagrant/.puppetlabs/etc'
    end
  end
end
