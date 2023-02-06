#!/bin/bash

set -ex

kubectl apply -f openstack/packstack_deployment.yml

while ! kubectl get deployment -n konveyor-forklift packstack; do sleep 10; done
kubectl wait deployment -n konveyor-forklift packstack --for condition=Available=True --timeout=180s

source openstack/utils.sh
run_command_deployment healthcheck
run_command_deployment bash /create-cirros.sh
sleep 2

# get the VM id and source it
OS_VM_ID=$(openstack_pod server list -c ID -f value)
export OS_VM_ID

# get the environment file from kind and source it
get_keystonerc "/tmp/e2e_env_vars.sh"
. /tmp/e2e_env_vars.sh

