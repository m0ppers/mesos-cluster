#!/bin/sh

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <mesos-cluster-workdir> [--num-slaves=<num-slaves>] [<additional-docker-options>]"
  exit 99
fi

WORKDIR=$1
NUM_SLAVES=3

shift

case $1 in 
  --num-slaves=*)
  NUM_SLAVES="${1#*=}"
  shift
  ;;
esac

DOCKER_OPTS=$@

if [ -z "$HOST_IP" ]; then
  HOST_IP=$(ip route get 255.255.255.255 | grep -Po '(?<=src )(\d{1,3}.){4}')
fi

DOCKER_SOCKET=${DOCKER_SOCKET:-'/var/run/docker.sock'}

docker -H unix://"$DOCKER_SOCKET" run --privileged -v "$DOCKER_SOCKET":"$DOCKER_SOCKET" -v "$WORKDIR":"$WORKDIR" $@ m0ppers/mesos-cluster $NUM_SLAVES $HOST_IP /data/mesos-cluster
