#!/bin/bash

set -ex

[ -z "${NFS_IP_ADDRESS}" ] && { echo "Provider cannot be installed - NFS_IP_ADDRESS env required" ; return 2 ;}
[ -z "${NFS_SHARE}" ] && { echo "Provider cannot be installed - NFS_SHARE env required" ; return 2 ;}

kubectl apply -f cluster/providers/openstack/manifests/packstack_deployment.yml
while ! kubectl get deployment -n konveyor-forklift packstack; do sleep 10; done
kubectl wait deployment -n konveyor-forklift packstack --for condition=Available=True --timeout=280s

# deploy csi-driver-nfs
cluster/providers/utils/deploy_csi_driver_nfs.sh "${NFS_IP_ADDRESS}" "${NFS_SHARE}"

# apply openstack volume populator crds
kubectl apply -f cluster/providers/openstack/manifests/osp-volume-populator-crd.yaml

# apply openstack volume populator deployment
kubectl apply -f cluster/providers/openstack/manifests/osp-volume-populator-deployment.yaml
kubectl wait deployment -n konveyor-forklift openstack-populator --for condition=Available=True --timeout=60s

sleep 5
source cluster/providers/openstack/utils.sh
# workaround for unable to attaching volume to a VM (missing mount for nova)
run_command_deployment fix_nova_mount
run_command_deployment packstack_update_endpoints
run_command_deployment packstack_patch_snapshots_support
run_command_deployment packstack_update_nfs_path  "${NFS_IP_ADDRESS}:${NFS_SHARE}"
run_command_deployment healthcheck
