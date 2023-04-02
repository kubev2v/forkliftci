#!/bin/sh
echo "Running $0"

set -xe

SCRIPT_PATH=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_PATH"`
PROVIDER_NAME=${1:-all}

echo "Building for provider ${PROVIDER_NAME}"

[ ! -d ${FORKLIFT_DIR:-forklift} ] && FORKLIFT_DIR="${SCRIPT_DIR}/forklift"

# verify there is WORKSPACE file
[ ! -e "${FORKLIFT_DIR:-forklift}/WORKSPACE" ] && { echo "couldnt find the forklift/ directory." ; exit 2; }


# Change the dir to FORKLIFT_DIR (default forklift)
cd ${FORKLIFT_DIR:-forklift}

export REGISTRY=localhost:5001
export REGISTRY_TAG=latest
export REGISTRY_ACCOUNT=""
export CONTAINER_CMD=$(which docker)

# REGISTRY_ACCOUNT cannot be empty with docker
if [ "${PROVIDER_NAME}" = "openstack" ]; then
    REGISTRY_ACCOUNT=ci make push-openstack-populator-image
fi
if [ "${PROVIDER_NAME}" = "ovirt" ]; then
    REGISTRY_ACCOUNT=ci make push-ovirt-populator-image
fi

REGISTRY_ACCOUNT=ci make push-populator-controller-image

bazel run push-forklift-api
bazel run push-forklift-controller
bazel run push-forklift-validation
bazel run push-forklift-operator

ACTION_ENV="--action_env CONTROLLER_IMAGE=${REGISTRY}/forklift-controller:${REGISTRY_TAG} \
    --action_env VALIDATION_IMAGE=${REGISTRY}/forklift-validation:${REGISTRY_TAG} \
    --action_env OPERATOR_IMAGE=${REGISTRY}/forklift-operator:${REGISTRY_TAG}
    --action_env API_IMAGE=${REGISTRY}/forklift-api:${REGISTRY_TAG}"

# if provider is ovirt or openstack, builder controller
if [ "${PROVIDER_NAME}" = "ovirt" ] || [ "${PROVIDER_NAME}" = "openstack" ]; then
    ACTION_ENV="$ACTION_ENV --action_env POPULATOR_CONTROLLER_IMAGE=${REGISTRY}/ci/populator-controller:${REGISTRY_TAG}"
fi

if [ "${PROVIDER_NAME}" = "ovirt" ]; then
    ACTION_ENV="$ACTION_ENV --action_env OVIRT_POPULATOR_IMAGE=${REGISTRY}/ci/ovirt-populator:${REGISTRY_TAG}"
fi

if [ "${PROVIDER_NAME}" = "openstack" ]; then
    ACTION_ENV="$ACTION_ENV --action_env OPENSTACK_POPULATOR_IMAGE=${REGISTRY}/ci/openstack-populator:${REGISTRY_TAG}"
fi

if [ "${PROVIDER_NAME}" = "vsphere" ]; then
    ACTION_ENV="$ACTION_ENV --action_env VIRT_V2V_IMAGE=quay.io/kubev2v/forklift-virt-v2v-stub:${REGISTRY_TAG} \
        --action_env VIRT_V2V_DONT_REQUEST_KVM=true "
fi

if [ "${PROVIDER_NAME}" = "all" ]; then
    ACTION_ENV="$ACTION_ENV --action_env VIRT_V2V_IMAGE=quay.io/kubev2v/forklift-virt-v2v-stub:${REGISTRY_TAG} \
        --action_env VIRT_V2V_DONT_REQUEST_KVM=true \
        --action_env OVIRT_POPULATOR_IMAGE=${REGISTRY}/ci/ovirt-populator:${REGISTRY_TAG} \
        --action_env OPENSTACK_POPULATOR_IMAGE=${REGISTRY}/ci/openstack-populator:${REGISTRY_TAG} \
        --action_env POPULATOR_CONTROLLER_IMAGE=${REGISTRY}/ci/populator-controller:${REGISTRY_TAG}"
fi

bazel run push-forklift-operator-bundle \
    --action_env CONTROLLER_IMAGE=${REGISTRY}/forklift-controller:${REGISTRY_TAG} \
    --action_env VALIDATION_IMAGE=${REGISTRY}/forklift-validation:${REGISTRY_TAG} \
    --action_env OPERATOR_IMAGE=${REGISTRY}/forklift-operator:${REGISTRY_TAG} \
    --action_env API_IMAGE=${REGISTRY}/forklift-api:${REGISTRY_TAG} \
    ${ACTION_ENV}

bazel run push-forklift-operator-index --action_env REGISTRY=${REGISTRY} --action_env REGISTRY_TAG=${REGISTRY_TAG} --action_env OPM_OPTS="--use-http"

