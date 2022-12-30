#!/bin/bash

set -ex

kubectl apply -f ovirt/patch.yml

docker build ovirt-imageio/ -t localhost:5001/imageio
docker push localhost:5001/imageio

kubectl apply -f ovirt/fakeovirt_deployment.yml
while ! kubectl get deployment -n konveyor-forklift fakeovirt; do sleep 10; done
kubectl wait deployment -n konveyor-forklift fakeovirt --for condition=Available=True --timeout=180s

kubectl apply -f ovirt-imageio/imageio_deployment.yml
while ! kubectl get deployment -n konveyor-forklift imageio; do sleep 10; done
kubectl wait deployment -n konveyor-forklift imageio --for condition=Available=True --timeout=180s

. ovirt/e2e_env_vars.sh
