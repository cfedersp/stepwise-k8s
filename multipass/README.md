Host Access
Networking: 1 interface for hosts, 1 interface for pod, service and control plane traffic
We could simply use iproute to route pod traffic, but then all that traffic originating from a VM gets shared with your entire house. Traffic originating from the host stays within that host.


Enable Full Disk Access to multipassd within Mac Settings -> Privacy & Security
multipass launch --name master --mount ~/Documents/projects/stepwise-k8s/ubuntu-utm-vms/:/usr/share/host
multipass exec master -- /bin/bash

Tagged VLAN created on host
Untagged VLAN created on host

MacOs doesn't use vconfig and ip, so we use the older ifconfig.
First view your hardware network interfaces
ifconfig -a
Create a new VLAN and tag it '3' as a virtual device on the physical network card 'en0'.
Assign the device gateway? an internet type ip address with the given value and have it listen to traffic within the given mask-space
sudo ifconfig vlan0 create
sudo ifconfig vlan0 vlan 3 vlandev en0
sudo ifconfig vlan0 inet 192.168.126.7 netmask 255.255.255.0

sudo ifconfig vlan0 up

Dont use DHCP:
# ipconfig set vlan0 DHCP


multipass launch --name master  --bridged --mount ~/Documents/projects/stepwise-k8s/ubuntu-utm-vms/:/usr/share/host --cloud-init cloud-init/config-node.yaml

within master:
vlan, kernel module, netplan config
sudo apt-get update
sudo apt-get install vlan
sudo modprobe 8021q


multipass stop master

multipass networks

multipass set local.bridged-network=vlan0
multipass set local.master.bridged=true

multipass start master
multipass shell master

within master:
ip add 

multipass delete master
multipass purge


A network bridge connects two or more network segments or interfaces together.
A network bridge to the host network will inherit? the hosts gateway, DNS and routes


Netplan can create VLAN interfaces directly on a physical interface or use a bridge to connect a VLAN interface to other network interfaces. 

brew install gnupg
./download-keys.sh 1.32


multipass launch --name master  --disk 20G --cpus 2 --memory 2G --bridged --mount ~/Documents/projects/stepwise-k8s/multipass/:/usr/share/host

multipass shell master
sudo /usr/share/host/vm-prep/apt-installs.sh
/usr/share/host/guest/cni/customize-pod-cidr.sh 1
sudo mkdir -p /etc/cni/net.d
sudo cp 11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 

sudo /usr/share/host/guest/master/start-master.sh
sudo /usr/share/host/guest/master/install-config.sh
/usr/share/host/guest/master/create-join-config.sh /usr/share/host/guest/generated  
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/custom-resources.yaml

launch-workers.sh 7

edit /etc/cloud/cloud.cfg and remove -resizefs
multipass set local.worker7.disk=100G

/usr/share/host/guest/cni/customize-pod-cidr.sh $(hostname | sed -n 's/.*\([0-9]\+\)/\1/p')
sudo mkdir -p /etc/cni/net.d
sudo cp 11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
/usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
sudo kubeadm join --config ./join-config.json  
mkdir -p ~/.kube; cp /usr/share/host/guest/generated/admin.conf ~/.kube/config 

kubectl get nodes

# sudo networksetup -add vmenet2 bridge101
# --cloud-init path-to-cloud-init

