#!/bin/bash

set -e

cleanup_kind_sshtunnel() {
    { [ -s /tmp/tunnel_id ] && [ -n "$(pgrep -f "$(cat /tmp/tunnel_id)")" ] ; } && \
    { echo "killing ssh PID $(pgrep -f "$(cat /tmp/tunnel_id)") " ; pkill -f "$(cat /tmp/tunnel_id)"; };
}

setup_kind_sshtunnel() {
    remote_port=$(kind get kubeconfig | grep server |  awk -F '1:' '{print $2}')
    ssh -f -N \
    -L ${remote_port}:127.0.0.1:${remote_port} ${REMOTE_DOCKER_HOST} \
    -L 5001:127.0.0.1:5001 ${REMOTE_DOCKER_HOST} 
    echo $remote_port > /tmp/tunnel_id
    echo "running ssh port ${remote_port} PID $(pgrep -f "$(cat /tmp/tunnel_id)") "
}

setup_remote_docker(){
    [ ! -n "$(ssh -qt ${REMOTE_DOCKER_HOST} docker ps)" ] && { echo "Couldnt reach remote docker host"; exit 2;  }

    export DOCKER_HOST=ssh://${REMOTE_DOCKER_HOST}
}
