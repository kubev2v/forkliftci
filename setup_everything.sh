#!/bin/sh

. ./install_kind.sh

./k8s-deploy-forklift.sh

./k8s-deploy-kubevirt.sh

./k8s-deploy-cert-manager.sh

. ./grant_permissions.sh

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
