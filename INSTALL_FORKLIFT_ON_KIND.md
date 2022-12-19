# Overview

This document explains how to install [kind](https://kind.sigs.k8s.io/)
("**k**ubernetes **in** **d**ocker"), create a
[kubernetes](https://kubernetes.io/) cluster, and install
[forklift](https://www.konveyor.io/tools/forklift/) on that cluster.

We also install [kubevirt](https://kubevirt.io) so that the cluster can be
used as a VM migration target.

Only the backend is installed, i.e. operator/controller/validation, without
the UI, because it is meant to be the target for running automated tests.


# Prerequisits

* [go](https://golang.org/)
* [docker](https://www.docker.com/) or [podman](https://podman.io/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/)


# All in one script

Run the script [setup_everything.sh](setup_everything.sh) to get kind,
create a cluster, install the latest release of forklift + kubevirt and
grant cluster-admin role to the kind default user _abcdef_. It will take a
few minutes and output progress info that might look like errors. Please be
patient.

See below for the individual steps.

In order to build & install from sources please see
[BUILD_AND_INSTALL_FORKLIFT_ON_KIND.md](BUILD_AND_INSTALL_FORKLIFT_ON_KIND.md).


# Get kind and create the cluster

Run the script [install_kind.sh](install_kind.sh) to get kind and
create a new cluster.
If the script is sourced instead it exports the variable $CLUSTER which can
be used as the URL prefix for queries:

    $ CLUSTER=`kind get kubeconfig | grep server | cut -d ' ' -f6`

# Install the latest release

Run the script [k8s-deploy-forklift.sh](k8s-deploy-forklift.sh) to get
the lates release of forklift from github and deploy it to the new cluster.
This can take a few minutes.


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


# Documentation

The Forklift API is described
[here](https://konveyor.github.io/forklift/migratingvms/migratecli/).
