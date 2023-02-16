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

# run VMware provider setup
./cluster/providers/vmware/setup.sh

# run ovirt provider setup
./cluster/providers/ovirt/setup.sh

# run openstack/packstack provider setup
./cluster/providers/openstack/setup.sh

# grant admin rights so its token can be used to access the API
k8s_grant_permissions

# patch StorageProfile with ReadWriteOnce Access
k8s_patch_storage_profile


echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
