# mesos-cluster

This will launch a fully fledged mesos cluster including marathon in one docker container.

## Background

We needed simple local mesos cluster to test our database against it. There are at least 2 other approaches
to enable local mesos cluster testing, namely:

   - minimesos
   - mesos cluster in 7 lines
   
In fact this project is partly built on the great efforts of the minimesos guys.
   
TODO: list pros and cons

## Usage

```
git clone https://github.com/m0ppers/mesos-cluster.git
cd mesos-cluster
./start-cluster.sh

Usage: ./start-cluster.sh <mesos-cluster-workdir> [--num-slaves=<num-slaves>] [<additional-docker-options>]
```

The whole cluster is sharing a workdir so that the mesos cluster can offer disk resources to tasks on the host.
It will create a new sub-workdir for each cluster spawned!

Optionally specify `num-slaves` and any options to pipe through to the docker daemon.

I am starting my cluster this way:

```
./start-cluster.sh /data/mesos-cluster/ --num-slaves=5 --rm --name mesos-cluster
```

This way I can always access my cluster via `mesos-cluster` and it will automatically clean itself up after stopping :)