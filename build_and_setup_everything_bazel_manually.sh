#!/bin/bash

set -e

source ./cluster/common.sh 
[[ -z "${REMOTE_DOCKER_HOST}" ]] || . ./cluster/kind/setup_remote_docker_kind.sh


[[ -z "${REMOTE_DOCKER_HOST}" ]] || setup_remote_docker

. ./cluster/kind/kind_with_registry.sh

./cluster/get_forklift_bazel.sh

./cluster/k8s-deploy-kubevirt.sh

./cluster/k8s-deploy-cert-manager.sh

./build_forklift_bazel.sh

./cluster/deploy_local_forklift_bazel.sh

./cluster/providers/vmware/setup.sh

./cluster/providers/ovirt/setup.sh

./cluster/providers/openstack/setup.sh

# grant admin rights so its token can be used to access the API
k8s_grant_permissions

# patch StorageProfile with ReadWriteOnce Access
k8s_patch_storage_profile


echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
