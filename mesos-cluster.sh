#!/bin/bash

if [ $# -lt 3 ]; then
  echo "Usage $0 <num-slaves> <hostip> <cluster-base-dir>"
  exit 99
fi

HOSTIP=$2
# strip any trailing slashes. this is actually needed. mesos ui will not be able to access the files otherwise :S
CLUSTER_BASE_DIR=$(echo $3 | sed -e 's/\/*$//g')

mountpoint $CLUSTER_BASE_DIR > /dev/null

if [ "$?" != "0" ]; then
  echo "$CLUSTER_BASE_DIR is not mounted"
  exit 98
fi

CLUSTER_WORK_DIR=$CLUSTER_BASE_DIR/`hostname`
IP=$(hostname --ip-address)



/etc/init.d/zookeeper start

let master_port=5050

mkdir -p "$CLUSTER_WORK_DIR"/mesos-master || exit 1

cat << EOF >/etc/supervisor/conf.d/mesos-master.conf
[program:mesos-master]
autostart=false
startsecs=3
command=mesos-master --no-hostname_lookup --zk=zk://$IP:2181/mesos --port=5050 --quorum=1 --registry=in_memory --roles=arangodb --work_dir=$CLUSTER_WORK_DIR/mesos-master
EOF

cat << EOF >/etc/supervisor/conf.d/marathon.conf
[program:marathon]
autostart=false
startsecs=1
command=marathon --master zk://$IP:2181/mesos --zk zk://$IP:2181/marathon --logging_level warn
EOF

let slave_port=31000
for i in `seq $1`; do
  SLAVE_DIR=$CLUSTER_WORK_DIR/mesos-slave-"$i"
  mkdir -p $SLAVE_DIR
  let slave_resource_start_port=slave_port+1
  let slave_resource_end_port=slave_resource_start_port+998
  iptables -t nat -A PREROUTING -p tcp -d $IP --dport $slave_resource_start_port:$slave_resource_end_port -j DNAT --to-destination $HOSTIP
  iptables -t nat -A OUTPUT -p tcp -d $IP --dport $slave_resource_start_port:$slave_resource_end_port -j DNAT --to-destination $HOSTIP
  # XXX don't get it :S
  iptables -t nat -A POSTROUTING  -j MASQUERADE
  cat << EOF >/etc/supervisor/conf.d/mesos-slave-"$i".conf
[program:mesos-slave-$i]
autostart=false
startsecs=1
command=mesos-slave --no-hostname_lookup --master=zk://$IP:2181/mesos --containerizers=docker --port=$slave_port --work_dir=$SLAVE_DIR --resources=mem(*):4096;disk(*):32768;cpus(*):4;ports(*):[$slave_resource_start_port-$slave_resource_end_port]
EOF
  let slave_port=slave_port+1000
done
supervisord -c /etc/supervisor/supervisord.conf
supervisorctl start mesos-master
for i in `seq $1`; do
  supervisorctl start mesos-slave-"$i"
done
supervisorctl start marathon

tail -f /var/log/supervisor/*

