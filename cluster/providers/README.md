# Migration source providers

## Installation
Provider can be installed on a K8s cluster :

`providers/install-provider.sh <provider-name>`

when `<provider-name>` can be either of:
- openstack
- ovirt
- vmware


## Openstack 
containerised [packstack](https://github.com/kubev2v/packstack-img)  deployment  that is tailor for forklift  migrations.


- Environment variables:

    | Name | Description | Required | 
    | ----------- | ----------- | ---  |
    | NFS_IP_ADDRESS |  NFS server  address used by cinder and volume populator (csi-driver-nfs) | yes | 
    | NFS_SHARE |  NFS export path. | yes |
    | KEYSTONE_USE_SSL | deploy  Keystone with SSL and self signed certs  | no |


## oVirt 
[fakeovirt](https://github.com/kubev2v/fakeovirt) and [ovirt-imageio](https://github.com/kubev2v/ovirt-imageio-server) deployments :
- Environment variables:

    | Name | Description | Required | 
    | ----------- | ----------- | ---  |
    | NFS_IP_ADDRESS |  NFS server  address used by cinder | yes | 
    | NFS_SHARE |  NFS export path. | yes |


## VMware
[VMware/vcsim](https://github.com/vmware/govmomi/tree/main/vcsim) deployment and vsphere-provider with stub vddkInitImage [image](../../stub-images/vddk-test-vmdk/BUILD.bazel).

