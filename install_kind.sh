#!/bin/sh

go install sigs.k8s.io/kind@v0.15.0

mkdir -p /var/tmp/kind_storage
chmod 777 /var/tmp/kind_storage

kind create cluster --config kind-config.yaml
kind get kubeconfig > /tmp/kubeconfig

kubectl apply -f add_pv.yml

export CLUSTER=`kind get kubeconfig | grep server | cut -d ' ' -f6`
