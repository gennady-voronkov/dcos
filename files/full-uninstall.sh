#!/usr/bin/env bash
#
export LD_LIBRARY_PATH=/opt/mesosphere/lib
export PATH=/opt/mesosphere/bin:/usr/bin:/bin:/sbin
export PYTHONUNBUFFERED=true
export PYTHONPATH=/opt/mesosphere/lib/python3.6/site-packages
#
systemctl stop dcos-adminrouter
systemctl stop dcos-checks-poststart
systemctl stop dcos-cosmos
systemctl stop dcos-diagnostics
systemctl stop dcos-metrics-master
systemctl stop dcos-gen-resolvconf
systemctl stop dcos-net-watchdog
systemctl stop dcos-epmd.service
systemctl stop dcos-oauth
systemctl stop dcos-history
systemctl stop dcos-pkgpanda-api
systemctl stop dcos-link-env
systemctl stop dcos-setup
systemctl stop dcos-log-master
systemctl stop dcos-signal
systemctl stop dcos-logrotate-master
systemctl stop dcos-3dt
systemctl stop dcos-download
systemctl stop dcos-navstar.service
systemctl stop dcos-spartan
systemctl stop dcos-metronome
systemctl stop dcos-minuteman
systemctl stop dcos-mesos-dns
systemctl stop dcos-mesos-master
systemctl stop dcos-marathon
systemctl stop dcos-net
systemctl stop dcos-exhibitor
#
sleep 1
/opt/mesosphere/bin/pkgpanda uninstall
rm -rf /opt/mesosphere /var/lib/mesos /var/lib/dcos /var/lib/zookeeper /var/log/mesos /etc/mesosphere /var/lib/mesosphere && \
rm -rf /etc/profile.d/dcos.sh /etc/systemd/journald.conf.d/dcos.conf /etc/systemd/system/dcos-cfn-signal.service /etc/systemd/system/dcos-download.service /etc/systemd/system/dcos-link-env.service /etc/systemd/system/dcos-setup.service /etc/systemd/system/multi-user.target.wants/dcos-setup.service /etc/systemd/system/multi-user.target.wants/dcos.target
rm -rf /run/dcos
rm -rf /etc/rexray/config.yml
rm -rf /etc/systemd/system/dcos*
rm -rf /tmp/dcos/dcos_install.sh
rm -rf /root/cert_dcos/*
kill -9 $(ps -ef|grep mesos|grep -v grep|awk '{print $2}')
systemctl daemon-reload
echo -e "nameserver 10.228.254.152\nnameserver 10.244.53.108\n" >/etc/resolv.conf
