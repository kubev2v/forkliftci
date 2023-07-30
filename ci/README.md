
# Forklift CI action collection
This section includes reusable standalone actions that can be used externally, consumed from the kubev2v/forklift repo (can be any other GH repo).

## build-and-setup 
Build and setup the forkliftci env with kind and prepare the env for e2e testing.
- Install kind (k8s) with a docker local image registry.
- Deploy kubevirt using manifests.
- Build forklift from source using bazel and push to the local registry.
- Deploy forklift from the local registry.
- Install source provider (openstack/ovirt/vsphere).

## prepare-ansible-secrets
The secrets are stored in GitHub settings of the kubev2v/forklift and kubev2v/forkliftci repositories.
They are stored in base64 and provide configuration 
for other actions, used by create-self-runner.


## create-self-runner
- Provisions a self-hosted runner from a Fedora template.
- join as GH hosted runner.

## run-suite
Wrapper for running a forklift e2e testing suite,
all the suites

## deploy-okd
Use Ansible to deploy OKD SNO instance on top of oVirt for e2e testing, refer to this document for the deployment flow.

## save-artifacts
Collect  K8s logs that are relevant for the forklift components. Useful for troubleshooting e2e migration failures, store them under gh-project job.