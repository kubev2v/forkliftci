
# Forklift CI action collection
This section include reusuable standalone actions that can be used externally,  consumed from the kubev2v/forklift repo (can be any other GH repo).

## build-and-setup 
Build and setup the forkliftci env with kind and prepare the env for e2e testing.
- install kind (k8s) with a local image docker registry
- deploy kubevirt using manifests.
- build forklift from source using bazel and push to the local registry.
- deploy forklift from the local registry.
- install source provider (openstack/ovirt/vsphere).

## prepare-ansible-secrets
the secrets stored in gh forklift and forkliftci settings.
they are stored in base64 and provide configuration 
for other actions, used by create-self-runner.


## create-self-runner
- provision Self hosted runner from a fedora template.
- join as GH hosted runner.

## run-suite
Wrapper for running a forklift e2e testing suite,
all the suites

## deploy-okd
Use ansible to deploy OKD SNO instance on top of oVirt for e2e testing,refer to this document for the deployment flow.

## save-artifacts
Collect  K8s logs that are relevant for the forklift components. Usefull for troubleshooting e2e migration failures , store them under gh-project job.
