#!/bin/sh

USER=system:bootstrap:`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-id}' | base64 -d`
echo "Assign cluster-admin role to user $USER"
kubectl create clusterrolebinding forklift-cluster-admin --clusterrole=cluster-admin --user=$USER

export TOKEN=`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-id}' | base64 -d`.`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-secret}' | base64 -d`
