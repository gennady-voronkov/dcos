#!/bin/ruby
require 'facter'
require 'json'
# Retrieves DC/OS version, if installed
Facter.add(:dcos_version) do
  setcode do
    version_file = '/opt/mesosphere/etc/dcos-version.json'
    if File.exists?(version_file)
      json = JSON.parse(File.read(version_file))
      if json.key? 'version'
        json['version']
      end
    end
  end
end

Facter.add(:dcos_config_path) do
  setcode do
    adminrouter_file = '/opt/mesosphere/etc/adminrouter-listen-open.conf'
    if File.exists?(adminrouter_file) and File.symlink?(adminrouter_file)
      config_path = Facter::Util::Resolution.exec("dirname $(readlink -f #{adminrouter_file})")
      File.expand_path('..', config_path)
    else
      Facter::Util::Resolution.exec("ls -d /opt/mesosphere/packages/dcos-config--*")
    end
  end
end

Facter.add(:check_bootstrap) do
  setcode do
    Facter::Util::Resolution.exec("/root/check_bootstrap.sh")
  end
end

Facter.add(:dcos_leader) do
  setcode do
    Facter::Util::Resolution.exec("echo stat|nc localhost 2181|grep ^Mode:|awk '{print $2}'")
  end
end

Facter.add(:dcos_myid) do
  setcode do
    Facter::Util::Resolution.exec("cat /var/lib/dcos/exhibitor/conf/zoo.cfg|grep $(/opt/mesosphere/bin/detect_ip)|cut -d= -f1|cut -d. -f2")
  end
end

Facter.add(:dcos_adminrouter_path) do
  setcode do
    adminrouter_service = '/etc/systemd/system/dcos-adminrouter.service'
    if File.exists?(adminrouter_service) and File.symlink?(adminrouter_service)
      service_path = Facter::Util::Resolution.exec("dirname $(readlink -f #{adminrouter_service})")
      File.expand_path('..', service_path)
    else
      Facter::Util::Resolution.exec("ls -d /opt/mesosphere/packages/adminrouter--*")
    end
  end
end
