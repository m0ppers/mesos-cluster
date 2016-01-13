#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage $0 <num-slaves> <hostip>"
  exit 99
fi

HOSTIP=$2

let master_port=5050

IP=$(hostname --ip-address)

mkdir -p /var/lib/mesos-master || exit 1

/etc/init.d/zookeeper start

cat << EOF >/etc/supervisor/conf.d/mesos-master.conf
[program:mesos-master]
command=mesos-master --no-hostname_lookup --zk=zk://$IP:2181/mesos --port=5050 --quorum=1 --registry=in_memory --roles=arangodb --work_dir=/var/lib/mesos-master
EOF

cat << EOF >/etc/supervisor/conf.d/marathon.conf
[program:marathon]
command=marathon --master zk://$IP:2181/mesos --zk zk://$IP:2181/marathon
EOF

let slave_resource_start_port=31000
for i in `seq $1`; do
  let slave_resource_end_port=slave_resource_start_port+999
  iptables -t nat -A PREROUTING -p tcp -d $IP --dport $slave_resource_start_port:$slave_resource_end_port -j DNAT --to-destination $HOSTIP
  iptables -t nat -A OUTPUT -p tcp -d $IP --dport $slave_resource_start_port:$slave_resource_end_port -j DNAT --to-destination $HOSTIP
  # XXX don't get it :S
  iptables -t nat -A POSTROUTING  -j MASQUERADE
  cat << EOF >/etc/supervisor/conf.d/mesos-slave-"$i".conf
[program:mesos-slave-$i]
command=mesos-slave --no-hostname_lookup --master=zk://$IP:2181/mesos --containerizers=docker --port=$slave_port --work_dir=/var/lib/mesos-master --resources=mem(*):2048;disk(*):16384;cpus(*):4;ports(*):[$slave_resource_start_port-$slave_resource_end_port]
EOF
  let slave_resource_start_port=slave_resource_end_port+1
done
supervisord -c /etc/supervisor/supervisord.conf

tail -f /var/log/supervisor/*

