require 'spec_helper'

describe 'dcos', :type => :class do
  let(:facts) { {
        :kernel => 'Linux',
        :operatingsystem => 'CentOS',
        :operatingsystemrelease => '7',
        :operatingsystemmajrelease => '7',
        :osfamily => 'RedHat',
        :interfaces => 'eth0',
        :networking => { :interfaces => { :eth0 => { :ip => '10.10.10.10'}}},
        :dcos_config_path => '/opt/mesosphere/packages/dcos-config--setup_8ec0bf2dda2a9d6b9426d63401297492434bfa47',
        :dcos_adminrouter_path => '/opt/mesosphere/packages/adminrouter--e0de512c046bee17e0d458d10e7c8c2b24f56fc7',
  } }

  let (:params) { {
      'cluster_name'       => 'dcos_presentation',
      'bootstrap_ip'       => '10.10.10.10',
      'bootstrap_port'     => '9090',
      'oauth_enabled'      => true,
      'part'               => 'master',
      'manage_adminrouter' => true,
      'root_dns'           => ['8.8.8.8'],
      'keep_backup'        => 'local',
      'restore_backup'     => 'nfs',
      'dcos_admin'         => 'gennady.voronkov@live.com',
  } }

  # dcos tests
  context 'dcos' do
      it { should compile }
      it { should contain_class('dcos') }
      it { should contain_class('Dcos::Backup') }
      it { should contain_class('Dcos::Config') }
      it { should contain_class('Dcos::Install') }
      it { should contain_class('Dcos::Master') }
      it { should contain_class('Dcos::Prerun') }
      it { should contain_class('Dcos::Restore') }
      it { should contain_class('Dcos::Params') }
      it { should contain_class('Dcos::Adminrouter') }
      it { should contain_class('Dcos::Bootstrap') }
      it { should contain_archive('dcos_generate_config_1.10.4.sh') }
      it { should contain_docker__image('nginx') }
      it { should contain_docker__run('bootstrap_run') }
      it { should contain_file('/opt/backups') }
      it { should contain_file('/opt/mesosphere/etc/mesos-master-extras') }
      it { should contain_file('/opt/zookeeper/zookeeper_backup.sh') }
      it { should contain_file('/opt/zookeeper/zookeeper_restore.sh') }
      it { should contain_file('/opt/zookeeper') }
      it { should contain_file('/root/cert_dcos') }
      it { should contain_file('/root/check_bootstrap.sh') }
      it { should contain_file('/root/full-uninstall.sh') }
      it { should contain_file('/root/mesos_role') }
      it { should contain_file('/tmp/dcos/dcos_install.sh') }
      it { should contain_file('/tmp/dcos') }
      it { should contain_file('/usr/local/bin/dcos') }
      it { should contain_file('/var/backups/') }
      it { should contain_file('/var/backups/zookeeper/dcos_presentation') }
      it { should contain_file('/var/backups/zookeeper') }
      it { should contain_file('/var/lib/dcos/exhibitor/zookeeper/snapshot/myid') }
      it { should contain_file_line('lang_env_var') }
      it { should contain_file_line('lc_env_var') }
      it { should contain_package('bc') }
      it { should contain_package('curl') }
      it { should contain_package('docker-common') }
      it { should contain_package('docker-selinux') }
      it { should contain_package('git') }
      it { should contain_package('ipset') }
      it { should contain_package('ipvsadm') }
      it { should contain_package('nc') }
      it { should contain_package('tar') }
      it { should contain_package('unzip') }
      it { should contain_package('wget') }
      it { should contain_package('xz') }
      it { should contain_group('nogroup') }
      it { should contain_cron('zookeeper_backup') }
      it { should contain_nfs__client__mount('/opt/backups') }
      it { should contain_archive('Install cli') }
      it { should contain_exec('check rpmdb') }
      it { should contain_exec('clean zookeeper.out') }
      it { should contain_exec('dcos master install') }
      it { should contain_exec('download bootstrap script') }
      it { should contain_exec('update') }
      it { should contain_exec('check dcos-mesos-master') }
      it { should contain_service('dcos-exhibitor') }
      it { should contain_service('dcos-mesos-master') }
      it { should contain_service('rexray') }
      it { should contain_exec('ntpdate sync') }
      it { should contain_file('/opt/mesosphere/packages/adminrouter--e0de512c046bee17e0d458d10e7c8c2b24f56fc7/nginx/conf/nginx.master.conf') }
      it { should contain_file('/opt/mesosphere/packages/dcos-config--setup_8ec0bf2dda2a9d6b9426d63401297492434bfa47/etc/adminrouter.env') }
      it { should contain_file('/opt/mesosphere/packages/dcos-config--setup_8ec0bf2dda2a9d6b9426d63401297492434bfa47/etc_master/adminrouter-listen-open.conf') }
      it { should contain_service('dcos-adminrouter') }
      it { should contain_exec('check time') }
      it { should contain_exec('waiting for sync time') }
      it { should contain_file('/root/check-time') }
      it { should contain_exec('run dcos_generate_config') }
      it { should contain_file('/mesos_data') }
      it { should contain_file('/opt/dcos/dcos_generate_config_1.10.4.sh') }
      it { should contain_file('/opt/dcos/genconf/config.yaml') }
      it { should contain_file('/opt/dcos/genconf/ip-detect') }
      it { should contain_file('/opt/dcos/genconf') }
      it { should contain_file('/opt/dcos') }
      it { should contain_file('/usr/local/bin/dcos-version') }
  end
end
