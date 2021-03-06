require 'rspec-puppet'

ENV['STRICT_VARIABLES'] = 'no'

base_dir = File.dirname(File.expand_path(__FILE__))

RSpec.configure do |c|
  c.mock_with :rspec
  c.module_path     = File.join(base_dir, 'fixtures', 'modules')
  c.manifest_dir    = File.join(base_dir, 'fixtures', 'manifests')
  c.manifest        = File.join(base_dir, 'fixtures', 'manifests', 'site.pp')
  c.environmentpath = File.join(Dir.pwd, 'spec')

  c.default_facts = {
    :osfamily       => 'RedHat',
    :concat_basedir => '/var/lib/puppet/concat'
  }

  # Coverage generation
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!
  end

end
require 'puppetlabs_spec_helper/module_spec_helper'
