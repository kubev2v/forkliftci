#!/bin/sh

. ./cluster/kind/install_kind.sh

./cluster/k8s-deploy-forklift.sh

./cluster/k8s-deploy-kubevirt.sh

./cluster/k8s-deploy-cert-manager.sh

source cluster/common.sh && k8s_grant_permissions

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
