#!/bin/bash

export REMOTE_DOCKER_HOST=192.168.2.130
[[ -z "${REMOTE_DOCKER_HOST}" ]] || { . ./cluster/kind/setup_remote_docker_kind.sh ; setup_remote_docker ;}

setup_kind_sshtunnel

kind get kubeconfig > /tmp/kubeconfig
