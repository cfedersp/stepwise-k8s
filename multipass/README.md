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

# make kubectl usable on host
cp $HOME/Documents/projects/stepwise-k8s/multipass/guest/generated/admin.conf $HOME/.kube/config

kubectl create secret docker-registry dockerhub \
      --docker-server=docker.io \
      --docker-username=<your-username> --docker-password=<your-password> --docker-email=<your-email>

# multipass exec master -- sudo mkdir -p /var/lib/data/openebs-volumes
kubectl get nodes
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml
kubectl create -k $HOME/Documents/projects/stepwise-k8s/multipass/guest/calico/
kubectl get tigerastatus
multipass exec master -- sudo mv /etc/cni/net.d/10-crio-ipv4-bridge.conflist /etc/cni/net.d/10-crio-ipv4-bridge.conflist.disabled

# create-join-config needs to use kubectl
multipass exec master -- /usr/share/host/guest/master/install-config.sh
multipass exec master -- /usr/share/host/guest/master/create-join-config.sh /usr/share/host/guest/generated  

guest/workers/launch-workers.sh reference 1 3

# add helm repo on host
helm repo add openebs https://openebs.github.io/openebs
helm repo update
kubectl explain storageclass
# SKIP: configure openebs to use host dirs, create hostpath SC
# kubectl apply -f guest/manifests/openebs-hostpath-sc.yaml 



# DONT install openebs because that is mostly for MinIO
helm install openebs --namespace openebs openebs/openebs --create-namespace --values helm-values/openebs-disable-mayastor-and-lvm.yaml
kubectl get pods -n openebs
kubectl annotate sc openebs-hostpath storageclass.kubernetes.io/is-default-class="true"

# if calico-nodes tokens expire 
    kubectl delete pods -n calico-system -l k8s-app=calico-node

# Provisioning Capacity: get taints and memory
kubectl describe nodes | grep Taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,MEMORY_CAPACITY:.status.capacity.memory

# Any software that uses HTTPS internally will require cert-manager. 
# We have no intention of managing internal certs manually and fortunately hostpath provisioner operator and webhook can use cert-manager provided self-signed certs.
kubectl create -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml
kubectl wait --for=condition=Available -n cert-manager --timeout=120s --all deployments

# install hostpath provisioner
kubectl create -f https://raw.githubusercontent.com/kubevirt/hostpath-provisioner-operator/main/deploy/namespace.yaml
kubectl create -f https://raw.githubusercontent.com/kubevirt/hostpath-provisioner-operator/main/deploy/webhook.yaml -n hostpath-provisioner
kubectl create -f https://raw.githubusercontent.com/kubevirt/hostpath-provisioner-operator/main/deploy/operator.yaml -n hostpath-provisioner

kubectl create -f guest/manifests/storage-pool-cr.yaml
kubectl create -f guest/manifests/hostpath-sc.yaml
kubectl create -f guest/manifests/logs-hostpath-sc.yaml

kubectl create -f guest/manifests/dag-pv.yaml

# install airflow:
git clone git@github.com:apache/airflow.git
kubectl create ns airflow
helm install airflow ../../oss/airflow/chart/ -n airflow --dry-run=client > airflow-3.0.6-chart.yaml

helm repo add apache-airflow https://airflow.apache.org
helm repo update
kubectl create ns airflow
kubectl create secret generic webserver-secret -n airflow --from-literal="webserver-secret-key=$(python3 -c 'import secrets; print(secrets.token_hex(16))')"
helm install airflow apache-airflow/airflow --namespace airflow --values helm-values/airflow.yaml
helm upgrade airflow apache-airflow/airflow --namespace airflow --set migrateDatabaseJob.useHelmHooks=false --set migrateDatabaseJob.enabled=false --set apiServer.waitForMigrations.enabled=false --set workers.waitForMigrations.enabled=false --set scheduler.waitForMigrations.enabled=false --values helm-values/airflow.yaml

https://groups.google.com/g/kubevirt-dev/c/zTnXrjYDDcc?pli=1

Delete the HPP
Delete the cluster, if necessary - done
Can create a kubevirt storage pool, but dont create app-data location or sc.
Since app sc is no longer the default, any log persistence must specify the new sc!
Remove dag processor's dag folder storageclass from helm values.
a hpp sc can be the default
sc name must be - so the helm chart will set it to "" - done
create hpp and sc, but not for app, since there is no need for it
create a hostpath PV manifest and apply it
update the helm chart..
OR start airflow

why was openebs switched out for kubevirt? not sure.
why is airflow helm chart still using 3.0.2 with FAB? 
what is create user doing?creating admin:admin
why is it running after I disabled hooks?
Solution:
dbmigration JOb needs more CPU and Memory
postgres need more CPU and Memory
nodes needed restart

New Problem:
kubevirt csi provisioner mounted applications for csi log volumes and never released that mount?
dag folder is using the same storage pool, but cant read my files since above mount is overlaying the host's files.


#
kubectl port-forward svc/airflow-api-server 8080:8080 --namespace airflow
Default Webserver (Airflow UI) Login credentials:
    username: admin
    password: admin
Default Postgres connection credentials:
    username: postgres
    password: postgres
    port: 5432


# Check db
kubectl exec -it airflow-postgresql-0  -n airflow -- psql -U postgres
\l
\du
\c postgres
\dt public.*

# Sample commands
kubectl annotate <resource_type>/<resource_name> <annotation_key>-
kubectl patch pvc/redis-db-airflow-redis-0 -p '{"metadata":{"finalizers":[]}}' -n airflow --type=merge

# install metrics server
https://medium.com/@cloudspinx/fix-error-metrics-api-not-available-in-kubernetes-aa10766e1c2f
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
{
"op": "add",
"path": "/spec/template/spec/hostNetwork",
"value": true
},
{
"op": "replace",
"path": "/spec/template/spec/containers/0/args",
"value": [
"--cert-dir=/tmp",
"--secure-port=4443",
"--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
"--kubelet-use-node-status-port",
"--metric-resolution=15s",
"--kubelet-insecure-tls"
]
},
{
"op": "replace",
"path": "/spec/template/spec/containers/0/ports/0/containerPort",
"value": 4443
}
]'

kubectl top pod -n airflow   


kubectl port-forward svc/airflow-api-server 8080:8080 --namespace airflow

# Issues:
need jsonfilter for Terminating pods
Expecting my dags folder to get mounted with its own PVC.
kubectl cp applications/airflow/dags/hello-taskflow.py airflow-dag-processor-7bb68f86c-s7tsg:/opt/airflow/dags/ -n airflow
worker has no memory request
how to view VM available memory?

Clean up:
helm uninstall airflow -n airflow 
kubectl delete pvc -n airflow data-airflow-postgresql-0 redis-db-airflow-redis-0

kubectl patch pvc data-airflow-postgresql-0  -p '{"metadata":{"finalizers":null}}' -n airflow
kubectl patch pvc redis-db-airflow-redis-0  -p '{"metadata":{"finalizers":null}}' -n airflow  


multipass restart master worker1 worker2 worker3 worker4 worker5 worker6 worker7 worker8
multipass stop --force worker2 worker3 worker4 worker5 worker6