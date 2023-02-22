#!/bin/bash
source cluster/providers/openstack/utils.sh

# create cirros VM instance using glance only
run_command_deployment packstack_create_cirros

# create volume (cinder) from image and start vm from it
run_command_deployment packstack_create_cirros_volume
sleep 2
# Create snapshot from cinder volume
run_command_deployment packstack_test_snapshot_creation

# get the VM id and source it
OS_VM_ID=$(openstack_pod server list -c ID -f value)
export OS_VM_ID

# get the environment file from kind and source it
get_keystonerc "/tmp/e2e_env_vars.sh"
. /tmp/e2e_env_vars.sh

