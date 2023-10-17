#!/bin/bash

set -e

PROVIDER_NAME=$1


SCRIPT_PATH=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_PATH"`

source ${SCRIPT_DIR}/../common.sh

case $PROVIDER_NAME in

  "all")
    echo "installing all providers"
    # apply k8s volume populator manifests
    k8s_apply_volume_populator    
    ${SCRIPT_DIR}/vmware/setup.sh
    ${SCRIPT_DIR}/ovirt/setup.sh
    [ ! -z "${INSTALL_NFS}" ] && ${SCRIPT_DIR}/utils/install_nfs.sh
    ${SCRIPT_DIR}/openstack/setup.sh
    ${SCRIPT_DIR}/openstack/create_test_vms.sh
    ${SCRIPT_DIR}/ova/setup.sh


    ;;
  "vsphere")
    echo "installing vsphere providers"

    # installs NFS for CSI
    [ ! -z "${INSTALL_NFS}" ] && ${SCRIPT_DIR}/utils/install_nfs.sh

    ${SCRIPT_DIR}/vmware/setup.sh
    ;;
  "ovirt")
    echo "installing ovirt providers"
    # apply k8s volume populator manifests
    k8s_apply_volume_populator

    # installs NFS for CSI
    [ ! -z "${INSTALL_NFS}" ] && ${SCRIPT_DIR}/utils/install_nfs.sh

    ${SCRIPT_DIR}/ovirt/setup.sh

    ;;  
  "openstack")
    echo "installing openstack providers" 
    # apply k8s volume populator manifests
    k8s_apply_volume_populator
      
    #installs nfs for CSI and opentack volumes
    [ ! -z "${INSTALL_NFS}" ] && ${SCRIPT_DIR}/utils/install_nfs.sh

    #create openstack - packstack deployment
    ${SCRIPT_DIR}/openstack/setup.sh

    #create sample VMs and volume disks for the tests
    ${SCRIPT_DIR}/openstack/create_test_vms.sh
    ;;
  "ova")
    echo "installing ova providers"
    # installs NFS for CSI
    [ ! -z "${INSTALL_NFS}" ] && ${SCRIPT_DIR}/utils/install_nfs.sh

    ${SCRIPT_DIR}/ova/setup.sh
    ;;  
  *) 
    echo "provider ${PROVIDER_NAME} set incorrectly"
    exit 5
    ;;
esac
echo "::endgroup::"
