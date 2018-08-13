require 'spec_helper_acceptance'
require 'beaker-rspec'
require 'puppet'

describe 'dcos_bootstrap' do
  context 'bootstrap' do
    # Using puppet_apply as a helper
    pp = <<-EOS
    node 'dcos-bootstrap.test.com' {
      class { 'dcos':
        cluster_name      => 'dcos_test',
        bootstrap_ip      => '10.10.10.10',
        bootstrap_port    => '9090',
        oauth_enabled     => true,
        dcos_version      => '1.10.4',
        ntp_server        => '10.254.140.21',
        root_dns          => ['8.8.8.8'],
        master_nodes      => ['10.10.10.11'],
        agent_nodes       => ['10.10.10.12'],
        publicagent_nodes => ['10.10.10.13'],
      }
    }
    EOS
    it 'should work idempotently with no errors' do
      apply_manifest(pp, :catch_failures => true)
    end

    describe package('docker-engine') do
      it { is_expected.to be_installed }
    end

    describe service('docker-bootstrap_run') do
      it { is_expected.to be_running }
    end
  end
end
