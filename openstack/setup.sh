#!/bin/bash

set -ex

kubectl apply -f openstack/packstack_deployment.yml

while ! kubectl get deployment -n konveyor-forklift packstack; do sleep 10; done
kubectl wait deployment -n konveyor-forklift packstack --for condition=Available=True --timeout=180s

source openstack/utils.sh
run_command_deployment healthcheck
run_command_deployment bash /create-cirros.sh
sleep 2
openstack_pod server list
