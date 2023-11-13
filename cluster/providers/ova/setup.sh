#!/bin/bash

set -ex

[ -z "${NFS_IP_ADDRESS}" ] && { echo "Provider cannot be installed - NFS_IP_ADDRESS env required" ; return 2 ;}
[ -z "${NFS_SHARE}" ] && { echo "Provider cannot be installed - NFS_SHARE env required" ; return 2 ;}

# Create a temporary directory for the NFS mount point
nfs_mount_point=$(mktemp -d)
ova_file_url="https://github.com/kubev2v/forkliftci/releases/download/v9.0/vm.ova"

# Mount the NFS share and check if the mount was successful
sudo mount -t nfs "$NFS_IP_ADDRESS:$NFS_SHARE" "$nfs_mount_point"
if [ $? -eq 0 ]; then
  echo "NFS share mounted successfully."
else
  echo "Error: NFS share mount failed."
  exit 1
fi

# Download the file and check if the copy was successful
echo "The VM ova file download started."
sudo wget -P "$nfs_mount_point" "$ova_file_url"
if [ $? -eq 0 ]; then
  echo "OVA file copied successfully to NFS share."
else
  echo "Error: OVA file copy failed."
fi

# Unmount the NFS share
sudo umount "$nfs_mount_point"

# Remove the temporary directory
rm -rf "$nfs_mount_point"

# Deploy csi-driver-nfs
kubectl get StorageClass nfs-csi 2>/dev/null || cluster/providers/utils/deploy_csi_driver_nfs.sh "${NFS_IP_ADDRESS}" "${NFS_SHARE}"
