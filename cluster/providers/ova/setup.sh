#!/bin/bash

set -ex

export NFS_IP_ADDRESS=$(ip route get 8.8.8.8 | awk '{ print $7 }' | head -1)
export NFS_SHARE="/home/nfsshare"

ova_file_url="https://github.com/kubev2v/forkliftci/releases/download/v8.0/vm.ova"

# Download the file and check if the copy was successful
echo "The VM ova file download started."
wget -P "$NFS_SHARE" "$ova_file_url"
if [ $? -eq 0 ]; then
  echo "OVA file copied successfully to NFS share."
else
  echo "Error: OVA file copy failed."
fi

# deploy csi-driver-nfs
cluster/providers/utils/deploy_csi_driver_nfs.sh "${NFS_IP_ADDRESS}" "${NFS_SHARE}"