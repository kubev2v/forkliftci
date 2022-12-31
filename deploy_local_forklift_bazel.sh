#!/bin/sh
echo "Running $0"

# Install olm
kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml

# Wait for olm operator to start
while ! kubectl get deployment -n olm olm-operator; do sleep 10; done
kubectl wait deployment -n olm olm-operator --for condition=Available=True --timeout=180s

# Deploy operator
kubectl apply -f forklift-k8s.yaml

# Wait for forklift operator to start, and create a controller instance
while ! kubectl get deployment -n konveyor-forklift forklift-operator; do sleep 10; done
kubectl wait deployment -n konveyor-forklift forklift-operator --for condition=Available=True --timeout=180s

cat << EOF | kubectl -n konveyor-forklift apply -f -
apiVersion: forklift.konveyor.io/v1beta1
kind: ForkliftController
metadata:
  name: forklift-controller
  namespace: konveyor-forklift
spec:
  feature_ui: false
  feature_validation: true
  inventory_tls_enabled: false
  validation_tls_enabled: false
  feature_must_gather_api: false
  must_gather_api_tls_enabled: false
  ui_tls_enabled: false
  inventory_container_requests_cpu: "50m"
  validation_container_requests_cpu: "50m"
  controller_container_requests_cpu: "50m"
  api_container_requests_cpu: "50m"
EOF
