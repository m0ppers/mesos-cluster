#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <mesos-cluster-workdir> [--num-slaves=<num-slaves>] [--port-range=<port-range>] [<additional-docker-options>]"
  exit 99
fi

# ss -ltn sport ge :1024 and sport lt :61123

WORKDIR=$1
NUM_SLAVES=3

shift


while true; do
  case $1 in 
    --num-slaves=*)
    NUM_SLAVES="${1#*=}"
    shift
    ;;
    --port-range=*)
    PORT_RANGE="${1#*=}"
    shift
    ;;
    *)
    break
  esac
done

let PORTCOUNT=1000
let STARTPORT=10000

while [ -z "$PORT_RANGE" ]; do
  let ENDPORT=$STARTPORT+$PORTCOUNT
  let NUM_LISTENERS=$(ss -t -l -n "sport gt $STARTPORT and sport le $ENDPORT" | tail -n +2 | wc -l)
  if [ "$NUM_LISTENERS" -eq 0 ]; then
    PORT_RANGE=$STARTPORT:$ENDPORT
  fi
  let STARTPORT=$STARTPORT+$PORTCOUNT
  if [ "$ENDPORT" -ge 65335 ]; then
    exit 2
  fi
done

DOCKER_OPTS=$@

if [ -z "$HOST_IP" ]; then
  HOST_IP=$(ip route get 255.255.255.255 | grep -Po '(?<=src )(\d{1,3}.){4}')
fi

DOCKER_SOCKET=${DOCKER_SOCKET:-'/var/run/docker.sock'}

docker -H unix://"$DOCKER_SOCKET" run --privileged -v "$DOCKER_SOCKET":"$DOCKER_SOCKET" -v "$WORKDIR":"$WORKDIR" $@ m0ppers/mesos-cluster $NUM_SLAVES $HOST_IP $PORT_RANGE $WORKDIR
