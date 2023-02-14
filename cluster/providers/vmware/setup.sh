#!/bin/bash

set -ex

kubectl apply -f ./cluster/providers/vmware/vcsim_deployment.yml

while ! kubectl get deployment -n konveyor-forklift vcsim; do sleep 5; done
kubectl wait deployment -n konveyor-forklift vcsim --for condition=Available=True --timeout=180s