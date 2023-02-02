#!/bin/bash

set -e

docker run -d --rm --name packstack  \
-v /lib/modules/:/lib/modules/ \
--privileged --cap-add ALL --security-opt seccomp=unconfined   --cgroup-parent=docker.slice \
-p 0.0.0.0:5000:5000 \
-p 0.0.0.0:8774:8774 \
-p 0.0.0.0:8775:8775 \
-p 0.0.0.0:8778:8778 \
-p 0.0.0.0:9292:9292 \
-p 0.0.0.0:9696:9696 \
quay.io/eslutsky/packstack:latest

sleep 300


source openstack/utils.sh
run_command healthcheck
openstack_container network list
run_command bash /create-cirros.sh
sleep 2
openstack_container server list
