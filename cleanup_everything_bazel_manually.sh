#!/bin/sh

kind delete cluster
docker stop kind-registry; docker rm kind-registry
rm -rf forklift/
