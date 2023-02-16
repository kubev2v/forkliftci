#!/bin/bash

set -ex

export ext_ip=$(ip route get 8.8.8.8 | awk '{ print $7 }' | head -1)
# set the EXTERNAL_IP env for the packstack container,its needed for accessing the NFS.
sed -i "s/<set_external_ip>/${ext_ip}/g" cluster/providers/openstack/packstack_deployment.yml

kubectl apply -f cluster/providers/openstack/packstack_deployment.yml
while ! kubectl get deployment -n konveyor-forklift packstack; do sleep 10; done
kubectl wait deployment -n konveyor-forklift packstack --for condition=Available=True --timeout=280s

# deploy csi-driver-nfs
cluster/providers/openstack/deploy_csi_driver_nfs.sh "${ext_ip}"


sleep 5
source cluster/providers/openstack/utils.sh
# workaround for unable to attaching volume to a VM (missing mount for nova)
run_command_deployment fix_nova_mount
run_command_deployment packstack_update_endpoints
run_command_deployment healthcheck
