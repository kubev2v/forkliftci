#!/bin/bash

# if none is provided set to all by default
[ ! -z "${PROVIDER_NAME}" ] || PROVIDER_NAME="all"

echo "::group::kind_installation"
. ./cluster/kind/kind_with_registry.sh

./cluster/k8s-deploy-kubevirt.sh

./cluster/k8s-deploy-cert-manager.sh

echo "::endgroup::"

echo "::group::build_forklift"
# build forklift and push to local registry
./build_forklift_bazel.sh
echo "::endgroup::"

echo "::group::deploy_local_forklift"

./cluster/deploy_local_forklift_bazel.sh
echo "::endgroup::"

echo "::group::${PROVIDER_NAME} setup"

source ./cluster/common.sh 

case $PROVIDER_NAME in

  "all")
    echo "installing all providers"
    # apply k8s volume populator manifests
    k8s_apply_volume_populator    
    ./cluster/providers/vmware/setup.sh
    ./cluster/providers/ovirt/setup.sh
    ./cluster/providers/openstack/install_nfs.sh
    ./cluster/providers/openstack/setup.sh
    ./cluster/providers/openstack/create_test_vms.sh

    ;;
  "vsphere")
    echo "installing vsphere providers"
    ./cluster/providers/vmware/setup.sh
    ;;
  "ovirt")
    echo "installing ovirt providers"
    # apply k8s volume populator manifests
    k8s_apply_volume_populator

    # installs NFS for CSI
    ./cluster/providers/openstack/install_nfs.sh
    ./cluster/providers/ovirt/setup.sh

    ;;  
  "openstack")
    echo "installing openstack providers" 
    # apply k8s volume populator manifests
    k8s_apply_volume_populator
      
    #installs nfs for CSI and opentack volumes
    ./cluster/providers/openstack/install_nfs.sh

    #create openstack - packstack deployment
    ./cluster/providers/openstack/setup.sh

    #create sample VMs and volume disks for the tests
    ./cluster/providers/openstack/create_test_vms.sh
    ;;
  *) 
    echo "provider ${PROVIDER_NAME} set incorrectly"
    exit 5
    ;;
esac
echo "::endgroup::"

# grant admin rights so its token can be used to access the API
k8s_grant_permissions

# patch StorageProfile with ReadWriteOnce Access
k8s_patch_storage_profile

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
