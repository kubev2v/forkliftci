#!/bin/sh

. ./kind_with_registry.sh

./get_forklift_bazel.sh

./k8s-deploy-kubevirt.sh

./k8s-deploy-cert-manager.sh

./build_forklift_bazel.sh

./deploy_local_forklift_bazel.sh

./vmware/setup.sh

./ovirt/setup.sh

. ./grant_permissions.sh

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
