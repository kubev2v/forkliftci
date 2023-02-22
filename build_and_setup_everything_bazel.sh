#!/bin/bash
source ./cluster/common.sh

# if none is provided set to all by default
[ ! -z "${PROVIDER_NAME}" ] || PROVIDER_NAME="all"

echo "::group::kind_installation"
. ./cluster/kind/kind_with_registry.sh

./cluster/k8s-deploy-kubevirt.sh

./cluster/k8s-deploy-cert-manager.sh

echo "::endgroup::"

echo "::group::build_forklift"
# build forklift and push to local registry
./build_forklift_bazel.sh
echo "::endgroup::"

echo "::group::deploy_local_forklift"

./cluster/deploy_local_forklift_bazel.sh
echo "::endgroup::"

echo "::group::${PROVIDER_NAME} setup"

./cluster/providers/install-provider.sh "${PROVIDER_NAME}"

echo "::endgroup::"

# grant admin rights so its token can be used to access the API
k8s_grant_permissions

# patch StorageProfile with ReadWriteOnce Access
k8s_patch_storage_profile

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
