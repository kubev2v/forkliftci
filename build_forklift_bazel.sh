#!/bin/sh
echo "Running $0"

set -xe

SCRIPT_PATH=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_PATH"`
PROVIDER_NAME=${1:-all}

echo "Building for provider ${PROVIDER_NAME}"

[ ! -d ${FORKLIFT_DIR:-forklift} ] && FORKLIFT_DIR="${SCRIPT_DIR}/forklift"

# verify there is WORKSPACE file
[ ! -e "${FORKLIFT_DIR:-forklift}/WORKSPACE" ] && FORKLIFT_DIR="${SCRIPT_DIR}/forklift"


# Change the dir to FORKLIFT_DIR (default forklift)
cd ${FORKLIFT_DIR:-forklift}

export XDG_RUNTIME_DIR="$(mktemp -p /tmp -d xdg-runtime-XXXXXX)"


export REGISTRY=localhost:5001
export REGISTRY_TAG=latest
export REGISTRY_ORG="kubev2v"
export CONTAINER_CMD=$(which docker)

CONTAINER_RUNTIME="$(basename ${CONTAINER_CMD:-$(command -v podman || command -v docker)})"
if [ ! -z "${XDG_RUNTIME_DIR}" ]; then
    PODMAN_AUTH_FILE="${XDG_RUNTIME_DIR}/containers/auth.json"
    if [ "${CONTAINER_RUNTIME}" == "podman" ]; then
        if [ -e "${PODMAN_AUTH_FILE}" ]; then
            DOCKER_CONFIG="$(mktemp -d)"
            DOCKER_AUTH_FILE="${DOCKER_CONFIG}/config.json"
            cp "${PODMAN_AUTH_FILE}" "${DOCKER_AUTH_FILE}"
            export DOCKER_CONFIG
        else
            unset DOCKER_CONFIG
        fi
    fi
fi


if [ "${PROVIDER_NAME}" = "ovirt" ]; then
    make push-ovirt-populator-image \
        push-populator-controller-image push-api-image push-controller-image push-validation-image push-operator-image \
        push-operator-bundle-image push-operator-index-image \
        OPM_OPTS="--use-http" BUILD_OPT="--network=host"
fi

if [ "${PROVIDER_NAME}" = "openstack" ]; then
    make push-openstack-populator-image \
        push-populator-controller-image push-api-image push-controller-image push-validation-image push-operator-image \
        push-operator-bundle-image push-operator-index-image \
        OPM_OPTS="--use-http" BUILD_OPT="--network=host"
fi

if [ "${PROVIDER_NAME}" = "vsphere" ]; then
    make push-ovirt-populator-image \
        push-populator-controller-image push-api-image push-controller-image push-validation-image push-operator-image \
        push-operator-bundle-image push-operator-index-image \
        OPM_OPTS="--use-http" BUILD_OPT="--network=host" VIRT_V2V_IMAGE=quay.io/kubev2v/forklift-virt-v2v-stub:latest
fi

if [ "${PROVIDER_NAME}" = "ova" ]; then
    make push-ova-provider-server-image \
        push-populator-controller-image push-api-image push-controller-image push-validation-image push-operator-image \
        push-operator-bundle-image push-operator-index-image \
        OPM_OPTS="--use-http" BUILD_OPT="--network=host" VIRT_V2V_IMAGE=quay.io/kubev2v/forklift-virt-v2v-stub:latest
fi

if [ "${PROVIDER_NAME}" = "all" ] || [ "${PROVIDER_NAME}" = "" ]; then
    make push-ova-provider-server-image push-ovirt-populator-image push-openstack-populator-image push-ovirt-populator-image\
        push-populator-controller-image push-api-image push-controller-image push-validation-image push-operator-image \
        push-operator-bundle-image push-operator-index-image \
        OPM_OPTS="--use-http" BUILD_OPT="--network=host" VIRT_V2V_IMAGE=quay.io/kubev2v/forklift-virt-v2v-stub:latest
fi