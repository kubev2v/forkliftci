 #!/bin/bash

if [  -n "$(uname -a | grep Ubuntu)" ]; then
    sudo apt-get update -y
    sudo apt install nfs-kernel-server -y   
else
    sudo dnf install nfs-utils -y
fi  

sudo mkdir -p /home/nfsshare
sudo chown -R nobody:nogroup /home/nfsshare
sudo chmod 777 /home/nfsshare
sudo bash -c 'echo "/home/nfsshare  *(insecure,rw,no_root_squash)" >>/etc/exports'
sudo exportfs -a

if [  -n "$(uname -a | grep Ubuntu)" ]; then
    sudo systemctl restart nfs-kernel-server
else
    sudo systemctl restart nfs-server
fi  


