#!/bin/bash

set -ex

nfs_server_ip=$1

# Install latest csi-driver-nfs
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.1.0/deploy/install-driver.sh | bash -s v4.1.0 --


cat << EOF | kubectl apply -f -
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: ${nfs_server_ip}
  share: /home/nfsshare
  subDir: nfs-csi  
  # csi.storage.k8s.io/provisioner-secret is only needed for providing mountOptions in DeleteVolume
  csi.storage.k8s.io/provisioner-secret-name: "mount-options"
  csi.storage.k8s.io/provisioner-secret-namespace: "default"
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
---
kind: Secret
apiVersion: v1
metadata:
  name: mount-options
  namespace: default
data:
  mountOptions: bmZzdmVycz00LjE=
type: Opaque
EOF

