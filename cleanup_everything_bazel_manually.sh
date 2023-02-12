#!/bin/bash

[[ -z "${REMOTE_DOCKER_HOST}" ]] || { . ./setup_remote_docker_kind.sh ; setup_remote_docker ;}

kind delete cluster
docker stop kind-registry; docker rm kind-registry
rm -rf forklift/
