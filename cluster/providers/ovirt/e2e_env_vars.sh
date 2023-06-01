#!/bin/sh

export OVIRT_USERNAME=admin@internal OVIRT_PASSWORD=123456 OVIRT_URL=https://fakeovirt.konveyor-forklift:30001/ovirt-engine/api
export OVIRT_CACERT=$(pwd)/cluster/providers/ovirt/e2e_cacert.cer STORAGE_CLASS=nfs-csi OVIRT_VM_ID=31573c08-717b-43e0-825f-69a36fb0e1a1 OVIRT_INSECURE_VM_ID=4db71538-9255-4ba3-a291-1240682dd8c6
