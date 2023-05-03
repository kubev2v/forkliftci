#!/bin/bash

source ./cluster/okd-on-ovirt/utils.sh


# deploy okd on ovirt using ansible
run_podman_ansible_deploy

# get kubeconfig..
deploy_csi_nfs

# test cluster is available

# deploy hyperconverged operator
k8s_apply_hco

# deploy latest forklift operator using subscription
k8s_apply_forklift_latest
