#!/bin/sh

[[ -z "${REMOTE_DOCKER_HOST}" ]] || . ./setup_remote_docker_kind.sh


[[ -z "${REMOTE_DOCKER_HOST}" ]] || setup_remote_docker

. ./kind_with_registry.sh

./get_forklift_bazel.sh

./k8s-deploy-kubevirt.sh

./k8s-deploy-cert-manager.sh

./build_forklift_bazel.sh

./deploy_local_forklift_bazel.sh

./vmware/setup.sh

./ovirt/setup.sh

./openstack/setup.sh

. ./grant_permissions.sh

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
