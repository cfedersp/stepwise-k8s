# Purpose:
The purpose of the repo is to provide some simple scripts that install kubernetes on a set of VMs.
This is intended to illustrate the entire process so it can be understood, then adapted to your on-prem environment and improved and extended with your chosen distributed applications.
The directory structure is intended to be mounted by all VMs.
A mount script is provided that can be pasted into a native ssh terminal (not a UTM display window).  
**Regarding Ephemeral and Generated files:**
* Package keys are occasionally updated so they may be included in this repo, but you will update them manually at the start of this process.    
* The master node writes join-config and private keys to guest/generated folder, which is not committed to this repo.  
* Worker nodes will customize the join-config and CNI CIDR, writing only to their own internal HOME directory.

# Tested on:
UTM 4.6.2(104) on Apple M4 running Sequoai 15.2
 
# Process Overview:
## Prep host:  
Clone this repo  
Download latest crio and kubernetes package keys

## Setup base VM:
Share dir: $PROJECTS_DIR/stepwise-k8s/ubuntu-utm-vms  
Install OS from ISO  
install crio and kubernetes package keys  
Install kubernetes packages  
Enable and disable kernel parameters as required by kubernetes.  

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
And each node's CNI must contain a pod CIDR range of 10.85.X.0/24 (where X is consecutive)  
On each node, add routes to every other node

# Prep Host:
```
git clone git@github.com:cfedersp/stepwise-k8s.git  
cd ubuntu-utm-vms  
./host-prep/download-keys.sh  
```

# Setup Base VM:
Download ARM Image to your host:  
[Ubuntu Server ISO Download](https://ubuntu.com/download/server/arm)  
If you have an ISO, in UTM, select Virtualize, then browse to the ISO and select your machine settings.  
Specify share dir: $PROJECTS_DIR/stepwise-k8s/ubuntu-utm-vms  
Start the Created VM and Select "Install or Try Ubuntu" or wait for the countdown to install Ubuntu.  
Follow OS installation steps, being sure to include:
* Install SSH Server
* Import SSH key
* No snaps are necessary  
Then stop the VM  
Delete the USB drive so the bootloader will not stop for a prompt.  
Start the VM, noting the IP Address printed after login
Delete the contents of /etc/machine-id but dont delete the file.  
On your host, copy the mount script:
`cat vm-prep/pbcopy.txt | pbcopy`
ssh to the ip of your VM  using your favorite terminal.  
Clear the contents of etc/machine-id but keep the file  
paste into your new terminal  
```
chmod 775 mount-share.sh
sudo ./mount-share.sh
sudo /usr/share/host/guest/all-nodes/apt-crio-k8s-installs.sh
```
Clear the contents of etc/machine-id **but keep the file**
VM will shutdown.
Stop using the VM display other than getting the ip.


# Setup Master
Clone your base VM, give it a random mac, add 100G NVMe and a new name.  
Wait a couple minutes for UTM to finish copying.  
Start the VM.  
Change hostname:  
```
sudo /usr/share/host/vm-prep/set-hostname-reboot.sh master  
```

Configure CNI:
```
sudo mkdir -p /etc/cni/net.d  
sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/11-crio-ipv4-bridge.conflist  
```

Share join-config and kubeconfig with host:
```
sudo /usr/share/host/guest/master/start-master.sh  
sudo /usr/share/host/guest/master/install-config.sh  
sudo install -d /usr/share/host/guest/generated -o $(id -un) -g $(id -gn)  
sudo install -m 664 /etc/kubernetes/admin.conf /usr/share/host/guest/generated/  
/usr/share/host/guest/master/create-join-config.sh /usr/share/host/guest/generated  
```

# Setup Workers:
Clone your base VM, give it a random mac, add 100G NVMe and a new name.  
Wait a couple minutes for UTM to finish copying.  
Network: "Random"  
Disk: Add NVMe 100G  
System: 1 core  
Name: Worker1  
Start the VM.  
Change hostname  :
```
sudo /usr/share/host/vm-prep/set-hostname-reboot.sh worker1  
```
Configure CNI:
```
/usr/share/host/guest/cni/customize-pod-cidr.sh 1
sudo mkdir -p /etc/cni/net.d
sudo cp 11-crio-ipv4-bridge.conflist /etc/cni/net.d/  
```
Join the Kubernetes Cluster, make the admin keys available for CLI use, show cluster nodes.
```
/usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated  
sudo kubeadm join --config ./join-config.json  
mkdir ~/.kube  
cp /usr/share/host/guest/generated/admin.conf ~/.kube/config  
kubectl get nodes  
```

# Setup Network Routes:
Note all connectivity to master has been by ip address so far. This will allow pods to reach each other when they reside on different VMs  
```
python3 /usr/share/host/guest/all-nodes/gen-route-add.py cni $(route | grep default | awk '{print $NF}') 10.85.0.0 $(kubectl get nodes -o json | jq -j '[.items[].status.addresses[0].address] | join(" ")')
chmod 775 cni-routes.sh
sudo ./cni-routes.sh
```
