#!/bin/sh

go install sigs.k8s.io/kind@v0.22.0

mkdir -p /var/tmp/kind_storage
chmod 777 /var/tmp/kind_storage

kind create cluster --config cluster/manifests/kind-config.yaml
kind get kubeconfig > /tmp/kubeconfig

kubectl apply -f cluster/manifests/add_pv.yaml

export CLUSTER=`kind get kubeconfig | grep server | cut -d ' ' -f6`
