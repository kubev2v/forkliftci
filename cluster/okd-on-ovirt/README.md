# provision okd-sno cluster on top of oVirt

 deploy single node OKD using assisted installer on top of RHV,.

- deploy assisted installer service on  podman - [source](https://hackmd.io/tDnHM2BoQru0VgqMGI_Q5g)
    - `git clone https://github.com/openshift/assisted-service/`
    - Customize service URLs in `deploy/podman/okd-configmap.yml`
        ```
        ASSISTED_SERVICE_HOST:  <assisted-fqdn>:8090
        IMAGE_SERVICE_BASE_URL: http://<assisted-fqdn>8888
        SERVICE_BASE_URL: http://<assisted-fqdn>:8090
        ```
        note:  `<assisted-fqdn>`  should be accessible from  RHV okd network .
    - run `make deploy-onprem OKD=true`


-  create configuration yaml file in `.conf/okd-on-ovirt-config.yaml`:
    ```yaml
    # RHV network that will be use for the OKD vm
    okd_rhv_network: ovirtmgmt
    # OKD cluster name, must match the API FQDN.
    okd_cluster_name: ovirt25
    # Assisted service FQDN or ip address.
    assisted_fqdn: assisted.com
    okd_vm_mac_address: mac-address-vm
    okd_vm_ssh_public_key: 
    okd_base_domain: gcp.devcluster.openshift.com
    ovirt_engine_url: https://engine-fqdn/ovirt-engine/api
    ovirt_engine_username: admin@internal
    ovirt_engine_password: xxxxxx
    ovirt_storage_name: Default
    ovirt_cluster_name: Default
    ```
- run okd-on-rhv using ansible-runner container:
    ```bash
    podman run -ti --privileged  \
    -e HOME=/home/runner \
    -u root:root \
    -v ~/.ssh/:/home/runner/.ssh/ \
    -v $(pwd):/home/runner/okd-on-rhv/ \
    -w /home/runner/okd-on-rhv/ \
    quay.io/ovirt/ansible-runner:ovirt-46 ansible-playbook okd-on-ovirt-deploy.yml -e@.conf/okd-on-ovirt-secrets.yaml -e@okd-on-ovirt-config.yaml
    ```
    
    this playbook will:
    - create new OKD assisted cluster config + download assisted ISO.
    - upload the assisted generated ISO file to RHV.
    - create new RHV VM from the ISO with attached local disk .
    - start cluster installation throught assisted API .

# remove okd-sno cluster
- run:
    ```bash
    podman run -ti --privileged  \
    -e HOME=/home/runner \
    -u root:root \
    -v $(pwd):/home/runner/okd-on-rhv/ \
    -w /home/runner/okd-on-rhv/ \
    quay.io/ovirt/ansible-runner:ovirt-46 ansible-playbook okd-on-ovirt-deploy.yml -e@.conf/okd-on-ovirt-config.yaml  -t remove_cluster -e okd_cluster_id=${okd_assisted_cluster_uuid}
    ```
    
