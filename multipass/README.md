Questions:
does cni conf matter as long as it exists? need to test with static ipam and calico before installing calico.
I dont think it needs to be customized if we're enabling Calico, but if we keep static ipam obv it does need to have custom range per host.

Host Access
Networking: 1 interface for hosts, 1 interface for pod, service and control plane traffic
We could simply use iproute to route pod traffic, but then all that traffic originating from a VM gets shared with your entire house. Traffic originating from the host stays within that host.


Enable Full Disk Access to multipassd within Mac Settings -> Privacy & Security
multipass launch --name reference  --bridged  --mount ~/Documents/projects/stepwise-k8s/multipass/:/usr/share/host
# multipass mount $HOME/Documents/projects/stepwise-k8s/multipass refk8s:/usr/share/host --type classic
multipass exec reference -- sudo /usr/share/host/vm-prep/apt-installs.sh
multipass exec reference -- sudo /usr/share/host/vm-prep/kubernetes-packages.sh
multipass exec reference -- sudo shutdown

multipass clone reference --name master 
multipass set local.master.disk=100G
multipass set local.master.memory=2G
multipass set local.master.cpus=2
multipass start master

multipass exec master -- sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
multipass exec master -- sudo mkdir -p /etc/cni/net.d
multipass exec master -- sudo cp 11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
multipass exec master -- sudo /usr/share/host/guest/master/start-master.sh
multipass exec master -- sudo /usr/share/host/guest/master/install-config.sh
multipass exec master -- sudo mkdir -p /var/lib/data/openebs-volumes
multipass exec master -- kubectl get nodes
multipass exec master -- kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml
# multipass exec master -- kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/custom-resources.yaml
multipass exec master -- kubectl apply -k /usr/share/host/guest/calico/
multipass exec master -- kubectl get tigerastatus

Could not resolve CalicoNetwork IPPool and kubeadm configuration: IPPool 192.168.0.0/16 is not within the platform's configured pod network CIDR(s) [10.85.0.0/16]

multipass exec master -- /usr/share/host/guest/master/create-join-config.sh /usr/share/host/guest/generated  

multipass clone reference --name worker1
multipass set local.worker1.disk=100G
multipass set local.worker1.memory=1G
multipass clone reference --name worker2
multipass set local.worker2.disk=100G
multipass set local.worker2.memory=1G
multipass clone reference --name worker3
multipass set local.worker3.disk=100G
multipass set local.worker3.memory=1G
multipass clone reference --name worker4
multipass set local.worker4.disk=100G
multipass set local.worker4.memory=1G
multipass clone reference --name worker5
multipass set local.worker5.disk=100G
multipass set local.worker5.memory=1G
multipass clone reference --name worker6
multipass set local.worker6.disk=100G
multipass set local.worker6.memory=1G

multipass start worker1
multipass exec worker1 -- sudo mkdir -p /etc/cni/net.d
multipass exec worker1 -- sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
multipass exec worker1 -- /usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
multipass exec worker1 -- sudo kubeadm join --config ./join-config.json  
multipass exec worker1 -- sudo mkdir -p /var/lib/data/openebs-volumes
multipass exec master -- kubectl get nodes

multipass start worker2
multipass exec worker2 -- sudo mkdir -p /etc/cni/net.d
multipass exec worker2 -- sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
multipass exec worker2 -- /usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
multipass exec worker2 -- sudo kubeadm join --config ./join-config.json  
multipass exec worker2 -- sudo mkdir -p /var/lib/data/openebs-volumes
multipass exec master -- kubectl get nodes

multipass start worker3
multipass exec worker3 -- sudo mkdir -p /etc/cni/net.d
multipass exec worker3 -- sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
multipass exec worker3 -- /usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
multipass exec worker3 -- sudo kubeadm join --config ./join-config.json  
multipass exec worker3 -- sudo mkdir -p /var/lib/data/openebs-volumes
multipass exec master -- kubectl get nodes

multipass start worker4
multipass exec worker4 -- sudo mkdir -p /etc/cni/net.d
multipass exec worker4 -- sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
multipass exec worker4 -- /usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
multipass exec worker4 -- sudo kubeadm join --config ./join-config.json 
multipass exec worker4 -- sudo mkdir -p /var/lib/data/openebs-volumes
multipass exec master -- kubectl get nodes

multipass start worker5
multipass exec worker5 -- sudo mkdir -p /etc/cni/net.d
multipass exec worker5 -- sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
multipass exec worker5 -- /usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
multipass exec worker5 -- sudo kubeadm join --config ./join-config.json 
multipass exec worker5 -- sudo mkdir -p /var/lib/data/openebs-volumes
multipass exec master -- kubectl get nodes

multipass start worker6
multipass exec worker6 -- sudo mkdir -p /etc/cni/net.d
multipass exec worker6 -- sudo cp /usr/share/host/guest/cni/master-11-crio-ipv4-bridge.conflist /etc/cni/net.d/ 
multipass exec worker6 -- /usr/share/host/guest/workers/customize-join-config.sh /usr/share/host/guest/generated
multipass exec worker6 -- sudo kubeadm join --config ./join-config.json  
multipass exec worker6 -- sudo mkdir -p /var/lib/data/openebs-volumes
multipass exec master -- kubectl get nodes


# we're using Calico, so routes are managed automatically for us.

# make kubectl usable on host
cp Documents/projects/stepwise-k8s/multipass/guest/generated/admin.conf ~/.kube/config

# add helm repo on host
helm repo add openebs https://openebs.github.io/openebs
helm repo update
kubectl explain storageclass
# SKIP: configure openebs to use host dirs, create hostpath SC
kubectl apply -f guest/manifests/openebs-hostpath-sc.yaml 

# install openebs
helm install openebs --namespace openebs openebs/openebs --create-namespace --values helm/values/openebs-disable-mayastor-and-lvm.yaml
kubectl get pods -n openebs


multipass exec master -- sudo /usr/share/host/guest/master/start-master.sh

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

