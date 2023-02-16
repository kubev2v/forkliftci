# Overview

This document explains how to install [kind](https://kind.sigs.k8s.io/)
("**k**ubernetes **in** **d**ocker"), including a local docker registry,
create a [kubernetes](https://kubernetes.io/) cluster, build
[forklift](https://www.konveyor.io/tools/forklift/) from source and install
it on that cluster.

We also install [kubevirt](https://kubevirt.io) so that the cluster can be
used as a VM migration target.

Only the backend is installed, i.e. operator/controller/validation, without
the UI, because it is meant to be the target for running automated tests.

# Prerequisites
* [go](https://golang.org/)
* [docker](https://www.docker.com/) or [podman](https://podman.io/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [git](https://git-scm.com/)
* [bazel](https://bazel.build/)


# All in one script

Run the script [build_and_setup_everything_bazel_manually.sh]
(build_and_setup_everything_bazel_manually.sh) 

this script will:
- create a local docker registry
- download and create a [kind](https://kind.sigs.k8s.io/) K8s cluster
- get the latest forklift code  (https://github.com/kubev2v/forklift)
- build the forklift images using bazel
- push the images to the local registry using bazel
- deploy forklift from the local registry images
- install migration providers for e2e testing

# providers
we are installing those providers as part of k8s kind cluster :
- [VMware - vcsim](https://github.com/vmware/govmomi/blob/main/vcsim/README.md)
- [OpenStack - packstack](https://github.com/kubev2v/packstack-img)
- [oVirt - fakeovirt and ovirt-imageio](https://github.com/kubev2v/fakeovirt)


In order to just install the latest release of forklift please see
[INSTALL_FORKLIFT_ON_KIND.md](INSTALL_FORKLIFT_ON_KIND.md).  


# Verify that forklift is running

The kind container:

    $ docker container ls
    CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS          PORTS                       NAMES
    298d058aa24e   kindest/node:v1.25.0   "/usr/local/bin/entr…"   12 minutes ago   Up 12 minutes   127.0.0.1:36679->6443/tcp   kind-control-plane
    b7f23a116b8b   registry:2             "/entrypoint.sh /etc…"   12 minutes ago   Up 12 minutes   127.0.0.1:5001->5000/tcp    kind-registry

The running pods should look like this:

    $ kubectl get pod -n konveyor-forklift
    NAME                                                              READY   STATUS      RESTARTS   AGE
    cef4e22ed1b3d40ac67fe676ede6173d27cf3fac387c18ee8b65d8442bssfqg   0/1     Completed   0          4m16s
    forklift-controller-6857cc454b-j972t                              2/2     Running     0          3m
    forklift-operator-6b6d55f97f-52k6t                                1/1     Running     0          3m58s
    forklift-validation-6d46d4b679-cgqmb                              1/1     Running     0          2m58s
    konveyor-forklift-67rbj                                           1/1     Running     0          5m29s

Set CLUSTER and TOKEN (see above) and call:

    $ curl -k "$CLUSTER/apis/forklift.konveyor.io/v1beta1/namespaces/konveyor-forklift/providers" --header "Authorization: Bearer $TOKEN"

You can also create a port forwarding to the forklift inventory-service
(which is not exposed externally, by default):

    $ kubectl port-forward -n konveyor-forklift service/forklift-inventory 9090:8080

This allows you to call the service directly, like this:

    $ curl "http://localhost:9090/providers" --header "Authorization: Bearer $TOKEN"

Or just use _kubectl_ (which will say "No resources found in
konveyor-forklift namespace." until a provider has been created):

    $ kubectl get -n konveyor-forklift providers


# Cleanup

Steps for cleaning up, in case the process is to be repeated in the same
environment:

* Stop the registry container and delete it (_docker stop_, _docker container
  rm_).
* Delete the registry image and all forklift images (_docker rmi_).
* Destroy the kind cluster (_kind delete cluster_).
* Delete the kind image (_docker rmi_).
* Delete the checked out git repos for _forklift-operator_,
  _forklift-controller_, _forklift-validation_.


# Documentation

The Forklift API is described
[here](https://konveyor.github.io/forklift/migratingvms/migratecli/).
