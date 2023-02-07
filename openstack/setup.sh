#!/bin/bash

set -ex

export ext_ip=$(ip route get 8.8.8.8 | awk '{ print $7 }' | head -1)
# set the EXTERNAL_IP env for the packstack container,its needed for accessing the NFS.
sed -i "s/<set_external_ip>/${ext_ip}/g" openstack/packstack_deployment.yml


kubectl apply -f openstack/packstack_deployment.yml
while ! kubectl get deployment -n konveyor-forklift packstack; do sleep 10; done
kubectl wait deployment -n konveyor-forklift packstack --for condition=Available=True --timeout=280s

sleep 5
source openstack/utils.sh
run_command_deployment healthcheck

# workaround for unable to attaching volume to a VM (missing mount for nova)
run_command_deployment fix_nova_mount

# create cirros VM instance using glance only
run_command_deployment packstack_create_cirros

# create volume (cinder) from image and start vm from it
run_command_deployment packstack_create_cirros_volume
sleep 2

# get the VM id and source it
OS_VM_ID=$(openstack_pod server list -c ID -f value)
export OS_VM_ID

# get the environment file from kind and source it
get_keystonerc "/tmp/e2e_env_vars.sh"
. /tmp/e2e_env_vars.sh

