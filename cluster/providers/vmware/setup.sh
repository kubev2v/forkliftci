#!/bin/bash

set -ex

[ -z "${NFS_IP_ADDRESS}" ] && { echo "Provider cannot be installed - NFS_IP_ADDRESS env required" ; return 2 ;}
[ -z "${NFS_SHARE}" ] && { echo "Provider cannot be installed - NFS_SHARE env required" ; return 2 ;}


kubectl apply -f ./cluster/providers/vmware/vcsim_certificate.yml
kubectl apply -f ./cluster/providers/vmware/vcsim_deployment.yml

while ! kubectl get deployment -n konveyor-forklift vcsim; do sleep 5; done
kubectl wait deployment -n konveyor-forklift vcsim --for condition=Available=True --timeout=180s

# deploy csi-driver-nfs if missing
kubectl get StorageClass nfs-csi 2>/dev/null || cluster/providers/utils/deploy_csi_driver_nfs.sh "${NFS_IP_ADDRESS}" "${NFS_SHARE}"
