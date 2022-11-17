kubectl apply -f ./vmware/vcsim_deployment.yml

#wget https://raw.githubusercontent.com/vmware/govmomi/master/Dockerfile.vcsim
#curl -L -o - https://github.com/vmware/govmomi/releases/latest/download/vcsim_$(uname -s)_$(uname -m).tar.gz | tar -xvzf - vcsim
cd vmware/
wget https://github.com/vmware/govmomi/releases/download/v0.29.0/vcsim_Linux_x86_64.tar.gz -O vcsim.tar.gz &&  tar xfz vcsim.tar.gz vcsim
wget https://github.com/vmware/govmomi/releases/download/v0.29.0/govc_Linux_x86_64.tar.gz -O govc.tar.gz && tar xfz govc.tar.gz govc


docker build -f Dockerfile.vcsim -t localhost:5001/vcsim:latest .
docker push localhost:5001/vcsim:latest
rm -rf govc.tar.gz govc vcsim.tar.gz vcsim
cd ../
kubectl apply -f ./vmware/  
while ! kubectl get deployment -n konveyor-forklift vcsim; do sleep 5; done
kubectl wait deployment -n konveyor-forklift vcsim --for condition=Available=True --timeout=180s

kubectl apply -f ./vmware/vsphere_provider.yml
kubectl apply -f ./manual_deploy_migration_vsphere.yml

# kubectl sniff vcsim-58df597c78-xpjbw -n konveyor-forklift -p
