#!/bin/bash
set +x
CONF_PATH="okd-on-ovirt-config.yaml"
SECRETS_PATH=".conf/okd-on-ovirt-secrets.yaml"
export KUBECONFIG=/tmp/kubeconfig

SCRIPT_PATH=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_PATH"`
source ${SCRIPT_DIR}/../common.sh


function start_gh_action_runner
 {
    docker run --privileged  \
    -e HOME=/home/runner \
    -v /tmp/id_ssh_rsa:/tmp/id_ssh_rsa \
    -v /tmp/test_output:/tmp/test_output \
    -v /tmp/id_ssh_rsa.pub:/tmp/id_ssh_rsa.pub \
    -u root:root \
    -v ${SCRIPT_DIR}/../okd-on-ovirt/roles/okd-on-ovirt:/home/runner/.ansible/roles/okd-on-ovirt \
    -v $(pwd)/:/home/runner/test-runner/ \
    -w /home/runner/test-runner \
    $(get_conf_value "${CONF_PATH}" "ansible_runner_image") \
    ansible-playbook gh-action-runner-vm-deploy.yml -e@"${CONF_PATH}" -e@"${SECRETS_PATH}" $@
}
