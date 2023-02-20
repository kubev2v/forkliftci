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

case $PROVIDER_NAME in

  "all")
    echo "installing all providers"
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
    # installs NFS for CSI
    ./cluster/providers/openstack/install_nfs.sh
    ./cluster/providers/ovirt/setup.sh
    ;;  
  "openstack")
    echo "installing openstack providers" 
      
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

source ./cluster/common.sh 

# grant admin rights so its token can be used to access the API
k8s_grant_permissions

# pactch StorageProfile with ReadWriteOnce Access
k8s_patch_storage_profile

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
