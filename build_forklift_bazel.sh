#!/bin/sh
echo "Running $0"

set -ex
SCRIPT_PATH=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_PATH"`

[ ! -d ${FORKLIFT_DIR:-forklift} ] && FORKLIFT_DIR="${SCRIPT_DIR}/forklift"

# verify there is WORKSPACE file
[ ! -e "${FORKLIFT_DIR:-forklift}/WORKSPACE" ] && { echo "couldnt find the forklift/ directory." ; exit 2; }


# Change the dir to FORKLIFT_DIR (default forklift)
cd ${FORKLIFT_DIR:-forklift}

export REGISTRY=localhost:5001
export REGISTRY_TAG=latest
export REGISTRY_ACCOUNT=""

bazel run push-forklift-api
bazel run push-forklift-controller
bazel run push-forklift-validation
bazel run push-forklift-operator
bazel run push-forklift-operator-bundle --action_env CONTROLLER_IMAGE=${REGISTRY}/forklift-controller:${REGISTRY_TAG} --action_env VALIDATION_IMAGE=${REGISTRY}/forklift-validation:${REGISTRY_TAG} --action_env OPERATOR_IMAGE=${REGISTRY}/forklift-operator:${REGISTRY_TAG} --action_env VIRT_V2V_IMAGE=quay.io/kubev2v/forklift-virt-v2v-stub:${REGISTRY_TAG} --action_env API_IMAGE=${REGISTRY}/forklift-api:${REGISTRY_TAG} --action_env VIRT_V2V_DONT_REQUEST_KVM=true
bazel run push-forklift-operator-index --action_env REGISTRY=${REGISTRY} --action_env REGISTRY_TAG=${REGISTRY_TAG} --action_env OPM_OPTS="--use-http"
