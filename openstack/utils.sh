container_name="packstack"
namespace_name=konveyor-forklift

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
kubectl exec -n ${namespace_name} -i deploy/packstack -- bash /test.sh
}


function get_keystonerc {
    localpath=$1
    
    kubectl cp  ${namespace_name}/$(echo_pod_name):/root/keystonerc_admin ${localpath}
}



function run_command_deployment {
        command=$@
    
    kubectl cp openstack/utils.sh  ${namespace_name}/$(echo_pod_name):/utils.sh
    kubectl exec -n ${namespace_name} -i deploy/packstack -- bash<<EOF
source /utils.sh
$command
EOF
}
function run_command {
    command=$@
    docker cp openstack/utils.sh ${container_name}:/utils.sh 
    docker exec -i ${container_name} bash<<EOF
source /utils.sh
$command
EOF
}

function openstack_container {
    command=$@

    openstack_wrapper "$command"
}

