#!/bin/bash

set -e

source ./cluster/common.sh 
[[ -z "${REMOTE_DOCKER_HOST}" ]] || . ./cluster/kind/setup_remote_docker_kind.sh


[[ -z "${REMOTE_DOCKER_HOST}" ]] || setup_remote_docker

# Create kind  cluster with local docker registry
. ./cluster/kind/kind_with_registry.sh

# clone the forklift repo
./cluster/get_forklift_bazel.sh

# deploy kubevirt
./cluster/k8s-deploy-kubevirt.sh

# deploy cert-manager
./cluster/k8s-deploy-cert-manager.sh

# build forklift from source and push to local docker registry
./build_forklift_bazel.sh

# deploy forklift from local docker registry
./cluster/deploy_local_forklift_bazel.sh

# grant admin rights so its token can be used to access the API
k8s_grant_permissions

# patch StorageProfile with ReadWriteOnce Access
k8s_patch_storage_profile

# optionally install provider (options: all/ovirt/openstack/vsphere)
[[ -z "${PROVIDER_NAME}" ]] || ./cluster/providers/install-provider.sh "${PROVIDER_NAME}"


echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
