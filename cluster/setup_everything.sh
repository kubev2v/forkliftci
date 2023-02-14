#!/bin/sh

. ./kind/install_kind.sh

./k8s-deploy-forklift.sh

./k8s-deploy-kubevirt.sh

./k8s-deploy-cert-manager.sh

source cluster/common.sh && k8s_grant_permissions

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
