require 'spec_helper_acceptance'
require 'beaker-rspec'
require 'puppet'

describe 'dcos_masters' do
  context 'master' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
      node 'dcos-master1.test.com' {
        class { 'dcos':
          cluster_name                     => 'dcos_test',
          bootstrap_ip                     => '10.10.10.10',
          bootstrap_port                   => '9090',
          oauth_enabled                    => true,
          part                             => 'master',
          keep_backup                      => 'local',
          restore_backup                   => 'local',
          ntp_server                       => 'pool.ntp.org',
          dcos_admin                       => 'gennady.voronkov@live.com',
          dcos_version                     => '1.10.4',
          mesos                            => {'MESOS_QUORUM' => '1'},
          manage_adminrouter               => false,
          adminrouter                      => {'server_name' => 'dcos-test.test.com'},
        }
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
    end

     describe service('dcos-exhibitor.service') do
       it { is_expected.to be_running }
     end

     describe service('dcos-mesos-master.service') do
       it { is_expected.to be_running }
     end
  end
end
