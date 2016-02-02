# mesos-cluster

This will launch a fully fledged mesos cluster including marathon in one docker container.

## Background

We needed simple local mesos cluster to test our database against it. There are at least 2 other approaches
to enable local mesos cluster testing, namely:

   - minimesos
   - mesos cluster in 7 lines
   
In fact this project is partly built on the great efforts of the minimesos guys.
   
This (opinionated) cluster has the following features:

   - supports starting bridged or host networked docker containers via the mesos docker executor
   - start as many slaves as you want directly via command line
   - fast startup
   - docker containers will start on the host (flat docker setup. No docker in docker)

## Prerequisites

If you are launching host networked docker containers mesos will by default use your hostname to determine the IP to bind to.
Make sure your hostname resolves to an IP which is routable for the mesos-cluster docker container. By default your hostname might resolve to 127.0.0.1 which is of course not reachable from the mesos-master inside the docker container.
In that case either hardcode your hostname inside /etc/hosts or use something like nss-myhostname.

## Usage

```
git clone https://github.com/m0ppers/mesos-cluster.git
cd mesos-cluster
./start-cluster.sh

Usage: ./start-cluster.sh <mesos-cluster-workdir> [--num-slaves=<num-slaves>] [--port-range=<port-range>] [<additional-docker-options>]
```

The whole cluster is sharing a workdir so that the mesos cluster can offer disk resources to tasks on the host.
It will create a new sub-workdir for each cluster spawned!

Optionally specify `--num-slaves and --port-range` and any options to pipe through to the docker daemon.

I am starting my cluster this way:

```
./start-cluster.sh /data/mesos-cluster/ --num-slaves=5 --rm --name mesos-cluster
```

This way I can always access my cluster via `docker exec -it mesos-cluster bash` and it will automatically clean itself up after stopping :)

To find out the IP of your docker cluster issue a

```
docker inspect <container-id|container-name> | grep "IPAddress\"" | tail -n1
```

The Marathon webinterface will be reachable on port 8080

The Mesos Master webinterface will be reachable on port 5050
