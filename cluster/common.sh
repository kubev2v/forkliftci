#!/bin/bash

function get_conf_value {
local conf_path=$1
local key=$2
val=$(python3 -c 'import yaml;import sys; \
data = yaml.full_load(open(sys.argv[1])); \
print(data[sys.argv[2]])' ${conf_path} ${key})
echo ${val}
}

function decode_secrets {
  cat ${SECRETS_PATH}.b64 | base64 -d >${SECRETS_PATH}.2
}
function generate_b64_conf {
  base64 -w 0 ${SECRETS_PATH} >${SECRETS_PATH}.b64
}


# grant admin rights so its token can be used to access the API
function k8s_grant_permissions {
    USER=system:bootstrap:`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-id}' | base64 -d`
    echo "Assign cluster-admin role to user $USER"
    kubectl create clusterrolebinding forklift-cluster-admin --clusterrole=cluster-admin --user=$USER

    export TOKEN=`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-id}' | base64 -d`.`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-secret}' | base64 -d`
}

# workaround to https://github.com/kubevirt/kubevirt/issues/7078
function k8s_patch_storage_profile {
    kubectl patch --type merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteOnce"]}]}}' StorageProfile standard
}

function k8s_apply_volume_populator {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-csi/volume-data-source-validator/v1.0.1/client/config/crd/populator.storage.k8s.io_volumepopulators.yaml
}