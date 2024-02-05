#!/bin/sh
echo "Running $0"

set -e

SCRIPT_PATH=`realpath "$0"`
SCRIPT_DIR=`dirname "$SCRIPT_PATH"`

[ ! -d ${FORKLIFT_DIR:-forklift} ] && FORKLIFT_DIR="${SCRIPT_DIR}/forklift"

# verify there is WORKSPACE file
[ ! -e "${FORKLIFT_DIR:-forklift}/WORKSPACE" ] && { echo "couldnt find the forklift/ directory." ; exit 2; }


# Change the dir to FORKLIFT_DIR (default forklift)
cd ${FORKLIFT_DIR:-forklift}

[ ! -e "${SCRIPT_DIR}/stub-images" ] && { echo "stub-images not found";exit 2; }

export REGISTRY_TAG=latest

# Copy the stub-images under the bazel workspace
cp -fr ${SCRIPT_DIR}/stub-images virt-v2v/cold
bazel run -package_path=virt-v2v/cold stub-images:push-forklift-virt-v2v-stub --verbose_failures
bazel run -package_path=virt-v2v/cold stub-images:push-vddk-test-vmdk --verbose_failures
