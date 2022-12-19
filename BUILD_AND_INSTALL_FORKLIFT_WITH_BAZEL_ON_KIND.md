# Overview

This document explains how to install [kind](https://kind.sigs.k8s.io/)
("**k**ubernetes **in** **d**ocker"), including a local docker registry,
create a [kubernetes](https://kubernetes.io/) cluster, build
[forklift](https://github.com/kubev2v/forklift) from source and install
it on that cluster.

We also install [kubevirt](https://kubevirt.io) so that the cluster can be
used as a VM migration target.

Only the backend is installed, i.e. operator/controller/validation, without
the UI, because it is meant to be the target for running automated tests.


# Prerequisits

* [go](https://golang.org/)
* [docker](https://www.docker.com/) or [podman](https://podman.io/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)
* [git](https://git-scm.com/)
* gcc with glibc-static package installed

# All in one script

Run the script [build_and_setup_everything_bazel_manually.sh]
(build_and_setup_everything_bazel_manually.sh) to get kind, create a local
docker registry, create a cluster, get the latest sources of forklift (from
https://github.com/kubev2v/forklift), patch them to use the local registry,
build the docker images, push the images to the local registry, deploy
forklift, install kubevirt and grant cluster-admin role to the kind default
user _abcdef_. It will take a few minutes and output progress info that
might look like errors. Please be patient.

See below for the individual steps.

In order to just install the latest release of forklift please see
[INSTALL_FORKLIFT_ON_KIND.md](INSTALL_FORKLIFT_ON_KIND.md).  
In order to build & install the older version of forklift, with individual
repos, please see [BUILD_AND_INSTALL_FORKLIFT_ON_KIND.md]
(BUILD_AND_INSTALL_FORKLIFT_ON_KIND.md).


# Get kind and create the cluster

Run the script [kind_with_registry.sh](kind_with_registry.sh) to get kind and
create a new cluster. (Original source:
https://kind.sigs.k8s.io/docs/user/local-registry/)
If the script is sourced instead it exports the variable $CLUSTER which can
be used as the URL prefix for queries:

    $ CLUSTER=`kind get kubeconfig | grep server | cut -d ' ' -f6`


# Get forklift sources

Run the script [get_forklift_bazel.sh](get_forklift_bazel.sh) to clone the
github repository.


# Build the docker images and push them to the local registry

Run the script [build_forklift_bazel.sh](build_forklift_bazel.sh).


# Deploy forklift

Run the script [deploy_local_forklift_bazel.sh](deploy_local_forklift_bazel.sh).


# Install kubevirt

Run the script [k8s-deploy-kubevirt.sh](k8s-deploy-kubevirt.sh) to deploy
kubevirt and everything it needs to the new cluster.
This can also take a moment.

# Install cert-manager
Run the script [k8s-deploy-cert-manager.sh](k8s-deploy-cert-manager.sh) to
deploy [cert-manager](https://cert-manager.io).

# Set Permissions

Since this is for test clusters only we use the simplest form of "access
control". Kind has a default user _abcdef_. We give this user admin rights
and then we use its bearer token to authenticate our API requests with curl.
This is totally **unsafe** and strictly for temporary test clusters!

Run the script [grant_permissions.sh](grant_permissions.sh) to give the
default user (_abcdef_) admin rights so its token can be used to access the
API. If You source that script instead then it also stores the token in the
variable $TOKEN. You can also set it manually:
    
    $ TOKEN=`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-id}' | base64 -d`.`kubectl get secrets -n kube-system -o jsonpath='{.items[0].data.token-secret}' | base64 -d`


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
* Delete the checked out git repo _forklift_rhy.


# Documentation

The Forklift API is described
[here](https://konveyor.github.io/forklift/migratingvms/migratecli/).
