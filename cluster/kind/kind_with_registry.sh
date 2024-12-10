#!/usr/bin/bash
echo "Running $0"

set -o errexit
[ -z "${REMOTE_DOCKER_HOST}" ] || . ./cluster/kind/setup_remote_docker_kind.sh

go install sigs.k8s.io/kind@v0.22.0

[ "$(type -P kind)" ] || ( echo "kind is not in PATH" ;  exit 2 )


mkdir -p /var/tmp/kind_storage
chmod 777 /var/tmp/kind_storage

# create registry container unless it already exists
reg_name='kind-registry'
reg_port='5001'
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "127.0.0.1:${reg_port}:5000" -e REGISTRY_STORAGE_DELETE_ENABLED=true --name "${reg_name}" \
     --network bridge \
    registry:2
fi

# create a cluster with the local registry enabled in containerd
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:v1.25.0@sha256:428aaa17ec82ccde0131cb2d1ca6547d13cf5fdabcc0bbecf749baa935387cbf
  extraMounts:
    - hostPath: /var/tmp/kind_storage
      containerPath: /data
  extraPortMappings:
    - containerPort: 30051
      hostPort: 30051
    - containerPort: 30050
      hostPort: 30050      
featureGates:
  LegacyServiceAccountTokenNoAutoGeneration: false      
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
    endpoint = ["http://${reg_name}:5000"]
EOF

kind get kubeconfig > /tmp/kubeconfig

# connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

[ -z "${REMOTE_DOCKER_HOST}" ] || { setup_kind_sshtunnel  ; trap cleanup_kind_sshtunnel ERR ;  } 

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

kubectl apply -f cluster/manifests/add_pv.yaml

export CLUSTER=`kind get kubeconfig | grep server | cut -d ' ' -f6`
export NODE_IP=`kubectl get nodes -o wide | grep control-plane | awk '{print $6}'`
