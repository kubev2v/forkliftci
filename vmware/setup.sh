#!/bin/bash

set -ex

kubectl apply -f ./vmware/vcsim_deployment.yml

while ! kubectl get deployment -n konveyor-forklift vcsim; do sleep 5; done
kubectl wait deployment -n konveyor-forklift vcsim --for condition=Available=True --timeout=180s


# workaround to https://github.com/kubevirt/kubevirt/issues/7078
kubectl patch --type merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteOnce"]}]}}' StorageProfile standard