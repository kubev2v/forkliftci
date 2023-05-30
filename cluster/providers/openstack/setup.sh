#!/bin/bash

set -ex

[ -z "${NFS_IP_ADDRESS}" ] && { echo "Provider cannot be installed - NFS_IP_ADDRESS env required" ; return 2 ;}
[ -z "${NFS_SHARE}" ] && { echo "Provider cannot be installed - NFS_SHARE env required" ; return 2 ;}

kubectl apply -f cluster/providers/openstack/manifests/packstack_deployment.yml
while ! kubectl get deployment -n konveyor-forklift packstack; do sleep 10; done
kubectl wait deployment -n konveyor-forklift packstack --for condition=Available=True --timeout=280s

# deploy csi-driver-nfs
cluster/providers/utils/deploy_csi_driver_nfs.sh "${NFS_IP_ADDRESS}" "${NFS_SHARE}"

sleep 5
source cluster/providers/openstack/utils.sh
# workaround for unable to attaching volume to a VM (missing mount for nova)
run_command_deployment fix_nova_mount
run_command_deployment packstack_update_endpoints
run_command_deployment packstack_patch_snapshots_support
run_command_deployment packstack_update_nfs_path  "${NFS_IP_ADDRESS}:${NFS_SHARE}"
run_command_deployment healthcheck

# add keystone SSL on port 5001
[ ! -z "${KEYSTONE_USE_SSL}" -a "${KEYSTONE_USE_SSL}" == "true" ] && run_command_deployment create_certs
[ ! -z "${KEYSTONE_USE_SSL}" -a "${KEYSTONE_USE_SSL}" == "true" ] && run_command_deployment add_apache_keystone_ssl

exit 0
