FROM ubuntu:15.04

# derived from several excellent base dockerfiles:
# minimesos
# Krijger/docker-cookbooks
MAINTAINER Andreas Streichardt <andreas@arangodb.com>

# supervisor installation && 
# create directory for child images to store configuration in
RUN apt-get update && \
apt-get -y install supervisor iptables && \
mkdir -p /var/log/supervisor && \
mkdir -p /etc/supervisor/conf.d
    
RUN echo "deb http://repos.mesosphere.io/ubuntu vivid main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
    apt-get update && \
    apt-get -y install curl mesos marathon

RUN curl -so /usr/bin/docker https://get.docker.com/builds/Linux/x86_64/docker-1.9.1 && chmod +x /usr/bin/docker

RUN rm -rf /var/lib/apt/lists/*
ADD ./mesos-cluster.sh /mesos-cluster.sh

ENTRYPOINT ["/mesos-cluster.sh"]
