#!/bin/bash

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

