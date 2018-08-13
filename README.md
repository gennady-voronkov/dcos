
# DC/OS nodes management

## Features

 * installation bootstrap server
 * installation and manage master servers
 * installation and manage public agent
 * installation and manage agent's attributes
 * support SSL certificates
 * managing authentication
 * clean up script
 * support auto backup/manual restore
 * support all dependency for dcos

## Installation bootstrap server
First of all it's necessary to deply bootstrap node, as soon bootstrap node up and running.
Master nodes will check bootstrap node and start automatic.
```yaml
---
classes:
  - dcos

dcos::cluster_name: 'dcos_presentation'
dcos::bootstrap_ip: '10.10.10.10'
dcos::bootstrap_port: '9090'
dcos::ntp_server: 'pool.ntp.org'
dcos::oauth_enabled: true
dcos::root_dns:
  - '8.8.8.8'
dcos::master_nodes:
  - '10.10.10.11'
  - '10.10.10.12'
  - '10.10.10.13'
  - '10.10.10.14'
  - '10.10.10.15'
dcos::agent_nodes:
  - '10.10.10.20'
dcos::publicagent_nodes:
  - '10.10.10.30'
```
## Installation master servers
When bootstrap URL is up and running, Puppet will try to install master DC/OS (in case that there's no previous installation in `/opt/mesosphere`)
just for master node:

```yaml
---
classes:
  - dcos

  dcos::cluster_name: 'dcos_presentation'
  dcos::bootstrap_ip: '10.10.10.10'
  dcos::bootstrap_port: '9090'
  dcos::oauth_enabled: true
  dcos::ntp_server: 'pool.ntp.org'
  dcos::part: 'master'
  dcos::keep_backup: 'local'
  dcos::dcos_admin: 'gennady.voronkov@live.com'
  dcos::dcos_user:
    - 'other_user@gmail.com'
    - 'other_user@live.com'
    - 'other_user@github.com'
  dcos::mesos:
    MESOS_QUORUM: 3
  dcos::manage_adminrouter: true
  dcos::adminrouter:
    server_name: 'dcos-presentation.yourdomain.yoursubdomain.com'
```
## Installation agents

```yaml
---
classes:
  - dcos

  dcos::cluster_name: 'dcos_presentation'
  dcos::bootstrap_ip: '10.10.10.10'
  dcos::bootstrap_port: '9090'
  dcos::part: 'slave'
  dcos::ntp_server: 'pool.ntp.org'
  dcos::agent::mesos:
    MESOS_CGROUPS_ENABLE_CFS: false
  dcos::agent::attributes:
    cloud: cloud_a
    location: spb
    os: centos
```

Puppet will fetch `$bootstrap_script` (defaults to `dcos_install.sh`) and attempt to run [Advanced installation](https://dcos.io/docs/1.10/installing/custom/advanced/) e.g. `bash dcos_install.sh slave`.

Role `slave_public` can be also configured in Hiera backend:
```yaml
---
classes:
  - dcos

  dcos::cluster_name: 'dcos_presentation'
  dcos::bootstrap_ip: '10.10.10.10'
  dcos::bootstrap_port: '9090'
  dcos::part: 'slave_public'
  dcos::ntp_server: 'pool.ntp.org'
  dcos::agent::mesos:
    MESOS_CGROUPS_ENABLE_CFS: false
  dcos::agent::attributes:
    cloud: cloud_a
    location: spb
    os: centos
```

## Usage

if it's necessry to use shared FS on all agents, You can add 'sharedfs' parameter into bootstrap and agent nodes.
Nfs server is configured on bootstrap node and nfs client on agents nodes.
if you use your own shared FS, you should replace 'nfs' value by 'local' or undef.
Default value of sharedfs is 'local'

```yaml
dcos::sharedfs: 'nfs'
```

There is some authentication features, to enable it you should place next line on bootstrap/masters nodes:

```yaml
dcos::oauth_enabled: true

```
NTP service is rather inportant at DCOS cluster, You have to point out here ntp server which can serve ntpdate command.
Without sync time. DCOS cluster won't work properly.
```yaml
dcos::ntp_server: 'pool.ntp.org'
```

There are backup and restore procedure. if you have NFS resorce in your environment you can point out next parameters:

```yaml
dcos::keep_backup: 'nfs'
dcos::restore_backup: 'nfs'
dcos::nfs_server: 'nfs-server.nfs-domain'
dcos::nfs_dir: 'nfs_dir'
```
After that backups keep on NFS server. it's rather convenient when you want to restore on other nodes.
if you place 'local' value in keep_backup parameter, then backups are saved here '/var/backups/zookeeper/$cluster_name'.
Default value of storing backups are 3 days. if you need more day, just point out in your YAML hiera nodes:
```yaml
dcos::backup_days: 7
```
To restore, it's necessary to run next script '/opt/zookeeper/zookeeper_restore.sh'
Restore script will take the lates backup and use the same clustername as in our YAML.
Also you can point out cluster name and backup file.
```
Usage: /opt/zookeeper/zookeeper_restore.sh [-c cluster_name] [-b <backup>]
  -c <cluster_name>      cluster_name
  -b <backup>            backup file to restore zookeeper data
```


Here you are cleanup procedure '/root/full-uninstall.sh' in case you need to recreate dcos cluster.


### Agent node:
Agent accepts `mesos` hash with `ENV` variables that will override defaults in `/opt/mesosphere/etc/mesos-slave-common`.

Disabling CFS on agent node:
```puppet
class{'dcos::agent':
  mesos => {
    'MESOS_CGROUPS_ENABLE_CFS' => false
  }
}
```

### Master node:

```puppet
class{'dcos':
  mesos => {
    'MESOS_QUORUM' => 2,
    'MESOS_max_completed_frameworks' => 50,
    'MESOS_max_completed_tasks_per_framework' => 1000,
    'MESOS_max_unreachable_tasks_per_framework' => 1000,
  }
}
```
`mesos` hash will create a file `/opt/mesosphere/etc/mesos-master-extras` overriding default `ENV` variables.

attributes:
```yaml
dcos::agent::attributes:
  dc: us-east
  storage: SATA
```

also existing facts can be easily used:
```yaml
dcos::agent::attributes:
  arch: "%{::architecture}"
  hostname: "%{::fqdn}"
```

### YAML (Hiera/lookup) configuration

Simply use supported parameters:
```yaml
dcos::agent::mesos:
  MESOS_CGROUPS_ENABLE_CFS: false
dcos::mesos:
  MESOS_QUORUM: 2
```

## Unit test

bundle exec rake spec

## Acceptance tests

### Test Bootstrap
BEAKER_destroy=no BEAKER_set=bootstrap bundle exec rspec spec/acceptance/bootstrap_spec.rb

### Test Master
BEAKER_set=master bundle exec rspec spec/acceptance/masters_spec.rb

### Destroy bootstrap box
vagrant destroy -f $(vagrant global-status|grep bootstrap|awk '{print $1}')
