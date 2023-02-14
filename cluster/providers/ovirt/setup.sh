#!/bin/bash

set -ex

kubectl apply -f cluster/providers/ovirt/patch.yml
kubectl apply -f cluster/providers/ovirt/fakeovirt_deployment.yml
kubectl apply -f cluster/providers/ovirt/ovirt_imageio_deployment.yml

while ! kubectl get deployment -n konveyor-forklift fakeovirt; do sleep 10; done
kubectl wait deployment -n konveyor-forklift fakeovirt --for condition=Available=True --timeout=180s

while ! kubectl get deployment -n konveyor-forklift ovirt-imageio; do sleep 10; done
kubectl wait deployment -n konveyor-forklift ovirt-imageio --for condition=Available=True --timeout=180s

. cluster/providers/ovirt/e2e_env_vars.sh
