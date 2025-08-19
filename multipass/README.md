Questions:
does cni conf matter as long as it exists? need to test with static ipam and calico before installing calico.
I dont think it needs to be customized if we're enabling Calico, but if we keep static ipam obv it does need to have custom range per host.

Host Access
Networking: 1 interface for hosts, 1 interface for pod, service and control plane traffic
We could simply use iproute to route pod traffic, but then all that traffic originating from a VM gets shared with your entire house. Traffic originating from the host stays within that host.

Host Prep:
./download-keys.sh 1.32

Enable Full Disk Access to multipassd within Mac Settings -> Privacy & Security
multipass launch --name reference  --bridged  --mount ~/Documents/projects/stepwise-k8s/multipass/:/usr/share/host
# multipass mount $HOME/Documents/projects/stepwise-k8s/multipass refk8s:/usr/share/host --type classic
multipass exec reference -- sudo /usr/share/host/vm-prep/apt-installs.sh
multipass exec reference -- sudo /usr/share/host/vm-prep/kubernetes-packages.sh
multipass exec reference -- sudo shutdown

multipass clone reference --name master 
multipass set local.master.disk=20G
multipass set local.master.memory=2G
multipass set local.master.cpus=2
multipass start master


Show storage:
sudo ls /var/root/Library/Application\ Support/multipassd/qemu/vault/instances/

plugins[].subnet is shorthand for plugins[].ranges[{subnet}]
conflist files include the plugins array. conf file can just have a single entry

If we dont put a conflist in place before calico..?
Problems: 
kubelet is trying to use containerd
mounts are gone
home dir files are gone - its as if worker state is almost completely gone, but services are still intact?
would be nice if we used vlan so traffic isn't going thru wifi router.

#############
### NOT done:
kubeadm config images pull
specify where on each host we want openebs to create host local storage
Add workers (relative) kubectl get nodes -o jsonpath='{.items[].metadata.name }'
use yaml tool to create netplan static ip
#############

# cni gives a path for coredns service. A bridge only works if your router allows hairpin traffic
multipass exec master -- sudo mkdir -p /etc/cni/net.d
multipass exec master -- ls /etc/cni/net.d
multipass exec master -- ifconfig
# multipass exec master -- sudo cp /usr/share/host/guest/cni/master-10-flannel-overlay.conflist /etc/cni/net.d/10-flannel-overlay.conflist
# crio will give you the bridge conflist to use, we just have to enable it
# But we know we are simply bootstrapping to Calico, so instead of the wide-range default bridge, we give a CRIO bridge with a specific, limited IP range that we know wont conflict with the Calico range.
multipass exec master -- sudo cp /usr/share/host/guest/cni/master-10-crio-ipv4-bridge.conflist /etc/cni/net.d/10-crio-ipv4-bridge.conflist
multipass exec master -- ifconfig
multipass exec master -- sudo /usr/share/host/guest/master/start-master.sh
multipass exec master -- sudo cp /etc/kubernetes/admin.conf /usr/share/host/guest/generated/
cp $HOME/Documents/projects/stepwise-k8s/multipass/guest/generated/admin.conf $HOME/.kube/config

# multipass exec master -- sudo mkdir -p /var/lib/data/openebs-volumes
kubectl get nodes
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml
kubectl create -k $HOME/Documents/projects/stepwise-k8s/multipass/guest/calico/
kubectl get tigerastatus
multipass exec master -- sudo mv /etc/cni/net.d/10-crio-ipv4-bridge.conflist /etc/cni/net.d/10-crio-ipv4-bridge.conflist.disabled

# create-join-config needs to use kubectl
multipass exec master -- /usr/share/host/guest/master/install-config.sh
multipass exec master -- /usr/share/host/guest/master/create-join-config.sh /usr/share/host/guest/generated  

guest/workers/launch-workers.sh reference 6


# we're using Calico, so routes are managed automatically for us.

# make kubectl usable on host
cp Documents/projects/stepwise-k8s/multipass/guest/generated/admin.conf ~/.kube/config

# add helm repo on host
helm repo add openebs https://openebs.github.io/openebs
helm repo update
kubectl explain storageclass
# SKIP: configure openebs to use host dirs, create hostpath SC
# kubectl apply -f guest/manifests/openebs-hostpath-sc.yaml 

kubectl create secret docker-registry dockerhub \
      --docker-server=docker.io \
      --docker-username=<your-username> --docker-password=<your-password> --docker-email=<your-email>

# install openebs
helm install openebs --namespace openebs openebs/openebs --create-namespace --values helm-values/openebs-disable-mayastor-and-lvm.yaml
kubectl get pods -n openebs
kubectl annotate sc openebs-hostpath storageclass.kubernetes.io/is-default-class="true"
# install airflow:
helm repo add apache-airflow https://airflow.apache.org
helm repo update
helm upgrade --install airflow apache-airflow/airflow --namespace airflow --create-namespace --values helm-values/airflow.yaml





