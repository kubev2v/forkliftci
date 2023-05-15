#!/bin/bash
set +x
CONF_PATH="okd-on-ovirt-config.yaml"
SECRETS_PATH=".conf/okd-on-ovirt-secrets.yaml"
export KUBECONFIG=/tmp/kubeconfig

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

function download_kubeconf {
  local path=$1
  local assisted_fqdn=$(get_conf_value "${SECRETS_PATH}" "assisted_fqdn")
  export okd_cluster_name=$(get_conf_value "${CONF_PATH}" "okd_cluster_name")
  local assisted_api="http://${assisted_fqdn}:8080/api/assisted-install/v2/clusters"
  local cluster_id=$(curl ${assisted_api} | jq -r '.[] |  select(.name==env.okd_cluster_name).id')
  
  curl ${assisted_api}/${cluster_id}/downloads/credentials?file_name=kubeconfig >${path}
}

function run_docker_terminal
 {
    docker run  -ti   \
    -e HOME=/home/runner \
    -v /tmp/id_ssh_rsa:/tmp/id_ssh_rsa \
    -v /tmp/id_ssh_rsa.pub:/tmp/id_ssh_rsa.pub \
    -v $(pwd):/home/runner/okd-on-rhv/ \
    -w /home/runner/okd-on-rhv/ \
    $(get_conf_value "${CONF_PATH}" "ansible_runner_image") \
    /bin/bash
}

function run_docker_create_vm
 {
    docker run --privileged  \
    -e HOME=/home/runner \
    -v /tmp/id_ssh_rsa:/tmp/id_ssh_rsa \
    -v /tmp/test_output:/tmp/test_output \
    -v /tmp/id_ssh_rsa.pub:/tmp/id_ssh_rsa.pub \
    -u root:root \
    -v $(pwd):/home/runner/okd-on-rhv/ \
    -w /home/runner/okd-on-rhv/ \
    $(get_conf_value "${CONF_PATH}" "ansible_runner_image") \
    ansible-playbook okd-on-ovirt-test.yml -e@"${CONF_PATH}" -e@"${SECRETS_PATH}" $@
}

function run_docker_ansible_deploy {
    docker run --privileged  \
    -e HOME=/home/runner \
    -u root:root \
    -v $(pwd):/home/runner/okd-on-rhv/ \
    -w /home/runner/okd-on-rhv/ \
    $(get_conf_value "${CONF_PATH}" "ansible_runner_image") \
    ansible-playbook okd-on-ovirt-deploy.yml -e@"${CONF_PATH}" -e@"${SECRETS_PATH}" $@
}

function run_docker_ansible_cleanup {
    docker run --privileged  \
    -e HOME=/home/runner \
    -u root:root \
    -v ~/.ssh/:/home/runner/.ssh/ \
    -v $(pwd):/home/runner/okd-on-rhv/ \
    -w /home/runner/okd-on-rhv/ \
    $(get_conf_value "${CONF_PATH}" "ansible_runner_image") \
    ansible-playbook okd-on-ovirt-deploy.yml -e@"${CONF_PATH}" -e@"${SECRETS_PATH}" $@ -t remove_cluster


    docker run --privileged  \
    -e HOME=/home/runner \
    -u root:root \
    -v ~/.ssh/:/home/runner/.ssh/ \
    -v $(pwd):/home/runner/okd-on-rhv/ \
    -w /home/runner/okd-on-rhv/ \
    $(get_conf_value "${CONF_PATH}" "ansible_runner_image") \
    ansible-playbook okd-on-ovirt-test.yml -e@"${CONF_PATH}" -e@"${SECRETS_PATH}" $@ -t cleanup
    
}

function run_podman_ansible_deploy {
    podman run -ti --privileged  \
    -e HOME=/home/runner \
    -u root:root \
    -v ~/.ssh/:/home/runner/.ssh/ \
    -v $(pwd):/home/runner/okd-on-rhv/ \
    -w /home/runner/okd-on-rhv/ \
    $(get_conf_value "${CONF_PATH}" "ansible_runner_image") \
    ansible-playbook okd-on-ovirt-deploy.yml  -e@"${CONF_PATH}" -e@"${SECRETS_PATH}"
}

# workaround to https://bugzilla.redhat.com/show_bug.cgi?id=2178990 on Fedora CoreOS 37.20230218.3.0
function k8s_apply_mco_container_use_devices {

stat /tmp/kubeconfig
export KUBECONFIG=/tmp/kubeconfig

mkdir -p /tmp/bin/
curl https://mirror.openshift.com/pub/openshift-v4/clients/oc/4.5/linux/oc.tar.gz | tar xvzf - -C /tmp/bin/ oc
cat << EOF | /tmp/bin/oc apply -f -
---
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: master
  name: 10-enable-container-use-devices-sebool
spec:
  config:
    ignition:
      version: 2.2.0
    systemd:
      units:
        - name: setsebool-container-use-devices.service
          enabled: true
          contents: |
            [Unit]
            Before=kubelet.service
            [Service]
            Type=oneshot
            ExecStart=setsebool container_use_devices true
            RemainAfterExit=yes
            [Install]
            WantedBy=multi-user.target
EOF
sleep 2
timeout 10m bash -c "until /tmp/bin/oc debug node/okd-sno -- chroot /host getsebool container_use_devices 2>/dev/null | grep 'container_use_devices --> on'; do sleep 10; done"
}

function k8s_apply_hyperconverged {
#TODO: repeat until down
cat << EOF | kubectl apply -f -
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: kubevirt-hyperconverged
spec:
EOF
}
function k8s_apply_hco {
cat << EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: kubevirt-hyperconverged
  annotations:
    openshift.io/sa.scc.mcs: s0:c26,c20
    openshift.io/sa.scc.supplemental-groups: 1000690000/10000
    openshift.io/sa.scc.uid-range: 1000690000/10000
  labels:
    kubernetes.io/metadata.name: kubevirt-hyperconverged
    openshift.io/cluster-monitoring: "true"
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/audit-version: v1.24
    pod-security.kubernetes.io/warn: privileged
    pod-security.kubernetes.io/warn-version: v1.24

---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: kubevirt-hyperconverged-group
  namespace: kubevirt-hyperconverged
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: community-kubevirt-hyperconverged
  namespace: kubevirt-hyperconverged
spec:
  source: community-operators
  sourceNamespace: openshift-marketplace
  name: community-kubevirt-hyperconverged
  channel: "stable" 
  installPlanApproval: Automatic
EOF

# wait until the hyperconverged pods will be up and running
until \
  [ $(oc get pods -n kubevirt-hyperconverged -l name=hyperconverged-cluster-webhook --no-headers | wc -l) -gt 0 ]; do
    echo "HCO webhook pod was not created yet."
    sleep 5s
done
oc wait pods -n kubevirt-hyperconverged -l name=hyperconverged-cluster-webhook --for=jsonpath='{.status.containerStatuses[0].ready}'=true --timeout=5m


# retry until success
timeout 5m bash -c "source utils.sh ; until k8s_apply_hyperconverged ; do sleep 20; done"

# make sure all the HCO components are finished
oc wait HyperConverged kubevirt-hyperconverged -n kubevirt-hyperconverged --for=condition=Available --timeout=15m

}


function k8s_apply_forklift_latest {
# create catalog from latest forklift-operator-index
cat << EOF | kubectl apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: konveyor-forklift
---
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: konveyor-forklift
  namespace: konveyor-forklift
spec:
  displayName: Latest Forklift
  publisher: Red Hat
  sourceType: grpc
  image: quay.io/kubev2v/forklift-operator-index:latest
  updateStrategy:
    registryPoll:
      interval: 10m0s
---      
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-mtv-group
  namespace: konveyor-forklift
spec:
  targetNamespaces:
   - konveyor-forklift
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: forklift-operator
  namespace: konveyor-forklift
spec:
  channel: development
  installPlanApproval: Automatic
  name: forklift-operator
  source: konveyor-forklift
  sourceNamespace: konveyor-forklift
EOF

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
  feature_ui_plugin: true
  feature_validation: true
  feature_volume_populator: true
  inventory_tls_enabled: true
  validation_tls_enabled: false
  must_gather_api_tls_enabled: false
  ui_tls_enabled: false
EOF

}

function enable_feautureGate {
  kubectl annotate --overwrite -n kubevirt-hyperconverged hco kubevirt-hyperconverged \
  kubevirt.kubevirt.io/jsonpatch='[{"op": "add", \
    "path": "/spec/configuration/developerConfiguration/featureGates/-", \
    "value": "KubevirtSeccompProfile" }]'

}
# setup env variables for e2e-sanity-ovirt test suite
function export_test_var {
    export OVIRT_USERNAME=$(get_conf_value "${SECRETS_PATH}" "ovirt_engine_username")
    export OVIRT_PASSWORD=$(get_conf_value "${SECRETS_PATH}" "ovirt_engine_password") 
    export OVIRT_URL=$(get_conf_value "${SECRETS_PATH}" "ovirt_engine_url") 
    export OVIRT_CUSTOM_ENV=true
    #extract the domain part from URL
    IFS=/ read -r prot _ engine_domain link <<<"$OVIRT_URL"

    curl -k  "https://${engine_domain}/ovirt-engine/services/pki-resource?resource=ca-certificate&format=X509-PEM-CA" >/tmp/engine.cer
    export OVIRT_CACERT=/tmp/engine.cer
    export STORAGE_CLASS=nfs-csi 
    export OVIRT_VM_ID=$(cat /tmp/test_output/test_vm_id)
    
}

function download_virtctl {
  export VERSION=v0.58.1
  wget https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64 -O /tmp/bin/virtctl
  chmod +x /tmp/bin/virtctl
  
}

function run_virtctl_cmd_timeout {
  sudo timeout 10m  bash -c "export KUBECONFIG=/tmp/kubeconfig ; until /tmp/bin/virtctl ssh root@fedora-test-vm -i /tmp/id_ssh_rsa --local-ssh -c hostname --local-ssh-opts='-o StrictHostKeyChecking=no'; do sleep 10 ; done "
}
