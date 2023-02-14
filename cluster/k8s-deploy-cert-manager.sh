#!/bin/bash

set -ex

# Install cert-manager (we use basic functionality of cert-manager, we don't have to use its latest version)
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.10.1/cert-manager.yaml
