container_name="packstack"
namespace_name=konveyor-forklift

# create logical volume 
function lv_create {
    size=$1
    loopdev=$(losetup -f)
    dd if=/dev/zero of=/tmp/cinder-volumes bs=1 count=0 seek=${size}G
    losetup ${loopdev} /tmp/cinder-volumes
    pvcreate ${loopdev}
    vgcreate cinder-volumes ${loopdev}
    lvcreate -T -L 2g cinder-volumes/cinder-volumes-pool
}

# cleanup logical volume
function lv_remove {
    lvremove cinder-volumes/cinder-volumes-pool -y
    for pv in $(pvdisplay -qC | grep dev | awk -e '{print $1}') ; do pvremove $pv --force --force -y ; done
    pvremove cinder-volumes -y
    vgremove cinder-volumes -y
    rm -rf /dev/cinder-volumes
    rm -rf /tmp/cinder-volumes
}

function get_osp_services {
   systemctl | grep -P "neutr|openstack|mariadb|glance|rabbit|libv|httpd" | awk '{print $1}'
}

function healthcheck {
   echo "systemctl state is $(systemctl is-system-running)"
   for svc in `get_osp_services`; do
    echo " $(systemctl status $svc | head -n 3)"
    echo " $(systemctl status $svc | grep Memory)"
   done
}

function source_keystonerc {
    docker cp ${container_name}:/root/keystonerc_admin keystonerc_admin
    source keystonerc_admin
    rm -rf keystonerc_admin
}
function openstack_wrapper {
    command=$@
    cat<<EOF >/tmp/test.cmd
    #!/bin/bash
    source /root/keystonerc_admin
    openstack ${command}
EOF
docker cp /tmp/test.cmd ${container_name}:/test.sh
docker exec -i ${container_name} bash /test.sh
}

function echo_pod_name {
pod_name=$(kubectl get pods -o=name -n ${namespace_name} | grep $container_name | cut -d/ -f2)
echo $pod_name
}

function openstack_pod {
    command=$@
    cat<<EOF >/tmp/test.cmd
    #!/bin/bash
    source /root/keystonerc_admin
    openstack ${command}
EOF

kubectl cp /tmp/test.cmd  ${namespace_name}/$(echo_pod_name):/test.sh
kubectl exec -n ${namespace_name} -i deploy/${container_name} -- bash /test.sh
}


function get_keystonerc {
    localpath=$1
    
    kubectl cp  ${namespace_name}/$(echo_pod_name):/root/keystonerc_admin ${localpath}
}



function run_command_deployment {
        command=$@
    
    kubectl cp cluster/providers/openstack/utils.sh  ${namespace_name}/$(echo_pod_name):/utils.sh
    kubectl exec -n ${namespace_name} -i deploy/packstack -- bash<<EOF
source /utils.sh
$command
EOF
}
function run_command {
    command=$@
    docker cp cluster/providers/openstack/utils.sh ${container_name}:/utils.sh 
    docker exec -i ${container_name} bash<<EOF
source /utils.sh
$command
EOF
}

function openstack_container {
    command=$@

    openstack_wrapper "$command"
}

function packstack_create_cirros {
    source /root/keystonerc_admin
    nova-manage cell_v2 discover_hosts
    sleep 2
    wget -q https://download.cirros-cloud.net/0.6.1/cirros-0.6.1-x86_64-disk.img -O /tmp/cirros-0.6.1.img
    openstack network create net-int
    openstack subnet create sub-int --network net-int --subnet-range 192.0.2.0/24

    openstack image create "cirros" --disk-format qcow2 \
    --container-format bare --public \
    --file /tmp/cirros-0.6.1.img 

    sleep 10

    openstack server create --image cirros --flavor m1.tiny --wait cirros --network net-int
}

function packstack_create_cirros_volume { 
    source /root/keystonerc_admin

    nova-manage cell_v2 discover_hosts

    # create cinder empty volume
    openstack volume create --size 1 empty_volume

    # create cinder volume from image
    openstack volume create --image cirros --size 1 cirros-volume

    # wait for the volume to be created
    sleep 10

    # boot VM instance from volume
    openstack server create --flavor m1.tiny --volume cirros-volume cirros-volume
    sleep 15
    openstack volume list 
    openstack server list
}

function fix_nova_mount {
  mkdir -p /var/lib/cinder/mnt/ 
  ln -s /var/lib/cinder/mnt/ /var/lib/nova/mnt
}

function packstack_update_endpoints {
    source /root/keystonerc_admin

    openstack endpoint list --interface public  -c ID -c URL -f value | grep 127.0.0.1 >/tmp/output

    new_host="packstack.${namespace_name}"
    while IFS=" " read -r id url;     do 
        openstack endpoint set --url ${url/127.0.0.1/"$new_host"} $id
    done  < /tmp/output
}

function packstack_test_snapshot_creation {
    source /root/keystonerc_admin

    # create snapshot from cirros-volume 
    snaphot_id=$(openstack volume snapshot create cirros-volume --force -c id  -f value 2>&1)
    [ $? -ne 0 ] && { echo "error creating snapshot: ${snaphot_id}" ; return 2; }
    
    sleep 5
    snapshot_status=$(openstack volume snapshot show ${snaphot_id} -c status -f value)
    [ "${snapshot_status}" != "available" ] && \
    { echo "snapshot ${snapshot_id} status ${snapshot_status}"; return 2;}

    openstack volume snapshot list
    openstack volume snapshot delete ${snaphot_id}

    return 0
}

# retry connecting to port until its reachable
function retry_port_reachable {
    local port=$1
    curl --connect-timeout 5  \
        --max-time 10 \
        --retry 5 \
        --retry-delay 0 \
        --retry-connrefused  \
        --retry-max-time 30 http://localhost:${port}
}


# update cinder nfs: ie 127.0.0.1:/home/nfsshare
function packstack_update_nfs_path {
    local nfs_path=$1

    echo $nfs_path >/etc/cinder/nfs_shares.conf
    systemctl restart openstack-cinder-volume.service
}

# patch packstack to allow NFS volume snapshots creation 
function packstack_patch_snapshots_support {
    
    [ -f "/etc/cinder/cinder.conf.orig" ] && return

    cat /etc/cinder/cinder.conf  | grep -v '#' | grep -v -e "^$"  >/etc/cinder/cinder.conf.new
sed -ie "s/\[backend_defaults\]//" /etc/cinder/cinder.conf.new
cat <<__EOF__  >>/etc/cinder/cinder.conf.new
[backend_defaults]
nfs_snapshot_support = true
nas_secure_file_operations = false
nas_secure_file_permissions = false
__EOF__

    mv /etc/cinder/cinder.conf /etc/cinder/cinder.conf.orig
    mv /etc/cinder/cinder.conf.new /etc/cinder/cinder.conf

    # workaround for https://bugzilla.redhat.com/show_bug.cgi?id=1936281 
    # until we find better solution
    sed -ie "s/context.project_domain_id/'default'/" /usr/lib/python3.6/site-packages/cinder/compute/nova.py
    systemctl restart openstack-cinder-api.service openstack-cinder-volume.service openstack-cinder-scheduler.service
    retry_port_reachable "8776"
}
