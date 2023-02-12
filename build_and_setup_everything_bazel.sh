#!/bin/sh

# if none is provided set to all by default
[ ! -z "${PROVIDER_NAME}" ] || PROVIDER_NAME="all"

. ./kind_with_registry.sh

./k8s-deploy-kubevirt.sh

./k8s-deploy-cert-manager.sh

./build_forklift_bazel.sh

./deploy_local_forklift_bazel.sh

case $PROVIDER_NAME in

  "all")
    echo "installing all providers"
    ./vmware/setup.sh
    ./ovirt/setup.sh
    ./openstack/install_nfs.sh
    ./openstack/setup.sh
    ./openstack/create_test_vms.sh

    ;;
  "vsphere")
    echo "installing vsphere providers"
    ./vmware/setup.sh
    ;;
  "ovirt")
    echo "installing ovirt providers" 
    ./ovirt/setup.sh
    ;;  
  "openstack")
    echo "installing openstack providers" 
      
    #installs nfs for CSI and opentack volumes
    ./openstack/install_nfs.sh

    #create openstack - packstack deployment
    ./openstack/setup.sh

    #create sample VMs and volume disks for the tests
    ./openstack/create_test_vms.sh
    ;;
  *) 
    echo "provider ${PROVIDER_NAME} set incorrectly"
    exit 5
    ;;
esac

. ./grant_permissions.sh

echo "CLUSTER=$CLUSTER"
echo "TOKEN=$TOKEN"
echo "NODE_IP=$NODE_IP"
