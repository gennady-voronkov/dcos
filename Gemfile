source :rubygems

gem 'bundler', '1.15.4'
gem 'metadata-json-lint', '1.2.2'
# NOTE: New version is 5.0.0, but it fails with rake spec. Using previous version 4.10.4!
gem 'puppet', '4.10.8'

group :development do
  gem 'guard', '2.14.1'	# requires Ruby version >= 2.2.5
  gem 'rubocop', '0.49.1'
end

group :test do
  gem 'rake', '12.3.1'
  gem 'rspec', '3.6.0'
  gem 'puppetlabs_spec_helper', '2.2.0'
  gem 'beaker-module_install_helper'
  gem 'beaker-puppet_install_helper'
  gem 'puppet-lint', '2.2.1'
  gem 'facter', '2.4.6'
  gem 'rspec-puppet', '2.5.0'
  gem 'parallel_tests', '2.14.1'
  gem 'beaker-rspec', '6.1.0'
  gem 'serverspec', '2.39.1'
  gem 'pry', '0.10.4'
end

gem 'gettext-setup', '>= 0.10', '< 1.0', :require => false
gem 'locale', '~> 2.1', :require => false
