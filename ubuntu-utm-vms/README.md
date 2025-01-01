# Overview:
Prep host:  
Clone repo  
Download latest crio and kubernetes package keys

## Setup base VM:
Share dir: $PROJECTS_DIR/stepwise-k8s/ubuntu-utm-vms  
Install OS  
install crio and kubernetes package keys 
Install kubernetes packages  
Enable kernel parameters required by kubernetes.
Change emulated network card  

## Setup Master
Clone base VM  
rename host, if necessary  
install CNI bridge config as is  
run scripts under guest/master  
upload master-join-config to host for use by workers.  
upload admin.conf to host for use by workers  

## Setup Workers:
Copy base VM  
rename host, if necessary  
customize the CNI bridge CIDR block and install it  
run scripts under guest/workers to customize the k8s join config and join the cluster.  
copy the admin.conf to $HOME/.kube/config, the location expected by kubectl  

## Setup Network Routes:
Given each VM has IP 192.168.64.X (where X is random)  
And each node's CNI config 10.85.X.0/24 (where X is consecutive)  
On each node, add routes to each node  

# Setup Base VM:
Download ARM Image:  
[Ubuntu Server ISO Download](https://ubuntu.com/download/server/arm)  
If you have an ISO, in UTM, select Virtualize, then browse to the ISO and select your machine settings.  
Start the Created VM and Select "Install or Try Ubuntu" or wait for the countdown to install Ubuntu.  
Follow OS installation steps, being sure to include:
* Install SSH Server
* Import SSH key
* No snaps are necessary
Then stop the VM  
Remove the USB drive  
Start the VM, noting the IP Address printed after login
Delete the contents of /etc/machine-id but dont delete the file.  
On your host, copy the mount script:
cat vm-prep/pbcopy.txt | pbcopy
ssh to the ip of your VM  using your favorite terminal.  
Clear the contents of etc/machine-id but keep the file
paste into your new terminal

chmod 775 mount-share.sh
sudo ./mount-share.sh
sudo /usr/share/host/guest/all-nodes/apt-crio-k8s-installs.sh
Clear the contents of etc/machine-id but keep the file
VM will shutdown.
Stop using the VM display other than getting the ip.


# Setup Master
Clone your base VM, give it a random mac, add 100G NVMe and a new name.
Wait a couple minutes for UTM to finish copying.
Start the VM.
Change hostname:
sudo /usr/share/host/vm-prep/set-hostname-reboot.sh master
sudo mkdir -p /etc/cni/net.d
sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/11-crio-ipv4-bridge.conflist
sudo /usr/share/host/guest/master/start-master.sh
sudo /usr/share/host/guest/master/install-config.sh
sudo install -d /usr/share/host/guest/generated -o $(id -un) -g $(id -gn)
sudo install -m 664 /etc/kubernetes/admin.conf /usr/share/host/guest/generated/
/usr/share/host/guest/master/create-join-config.sh /usr/share/host/guest/generated

# Setup Workers:
Clone your base VM, give it a random mac, add 100G NVMe and a new name.
Wait a couple minutes for UTM to finish copying.
Network: "Random"
Disk: Add NVMe 100G
System: 1 core
Name: Worker1
Start the VM.
Change hostname:
sudo /usr/share/host/vm-prep/set-hostname-reboot.sh worker1
/usr/share/host/guest/cni/customize-pod-cidr.sh 1
sudo mkdir -p /etc/cni/net.d
sudo cp 11-crio-ipv4-bridge.conflist /etc/cni/net.d/

/usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
sudo kubeadm join --config ./join-config.json
mkdir ~/.kube
cp /usr/share/host/guest/generated/admin.conf ~/.kube/config
kubectl get nodes

# Setup Network Routes:
Note all connectivity to master has been by ip address so far. This will allow pods to reach each other when they reside on different VMs  
python3 /usr/share/host/guest/all-nodes/gen-route-add.py cni $(route | grep default | awk '{print $NF}') 10.85.0.0 $(kubectl get nodes -o json | jq -j '[.items[].status.addresses[0].address] | join(" ")')  
chmod 775 cni-routes.sh  
sudo ./cni-routes.sh
