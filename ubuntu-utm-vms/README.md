# Purpose:
The purpose of the repo is to provide some simple scripts that install kubernetes on a set of VMs on your VM manager's default Bridged Network.
This is intended to illustrate the entire process so it can be understood, then adapted to your ops environment and improved and extended with your chosen distributed applications.
This repo's directory structure is intended to be mounted by all VMs.
A mount script is provided that can be pasted into a native ssh terminal (not a UTM display window).  
**Regarding Ephemeral and Generated files:**
* Package keys are occasionally updated so they may be included in this repo, but you will update them manually at the start of this process.    
* The master node writes join-config and private keys to guest/generated folder, which is not committed to this repo.  
* Worker nodes will customize the join-config and CNI CIDR, writing only to their own internal HOME directory.  

Once your cluster is running, you will access it from the host and we can add applications like MinIO(an Object Store)  
Finally, we explore sophistications such as running on a separate private network or adding an ingress controller (may require components internal and external to your cluster).

# Tested on:
UTM 4.6.2(104) on Apple M4 running Sequoai 15.2
 
# Process Overview:
## Prep host:  
Create ~/.kube/ dir for CLI keys  
Install helm and kubectl so we can interact with the cluster once its running.  
Clone this repo  
Download latest crio and kubernetes package keys  

## Setup base linux VM:
Share dir: $PROJECTS_DIR/stepwise-k8s/ubuntu-utm-vms  
Install OS from ISO 

## Create base kubernetes VM: 
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
Make the extra disk available as part of a Volume Group
customize the CNI bridge CIDR block and install it  
run scripts under guest/workers to customize the k8s join config and join the cluster.  
copy the admin.conf to $HOME/.kube/config, the location expected by kubectl  

## Setup Network Routes:
Given each VM has IP 192.168.64.X (where X is random)  
And each node's CNI must contain a pod CIDR range of 10.85.X.0/24 (where X is consecutive)  
On each node, add routes to every other node

## Start using it:
Copy the keys required for the CLI to the preferred location
Run some test commands 
Install cool things.

## References:
https://min.io/docs/minio/kubernetes/upstream/operations/install-deploy-manage/deploy-minio-tenant-helm.html#deploy-tenant-helm
This was customized and checked in as a static manifest.
curl -sLo values.yaml https://raw.githubusercontent.com/minio/operator/master/helm/tenant/values.yaml
# Prep Host:
```
mkdir -p ~/.kube/
export HELM_INSTALL_DIR=$HOME/opt/utils
mkdir -p $HELM_INSTALL_DIR
export PATH=$HELM_INSTALL_DIR:$PATH
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
curl -L -o $HOME/opt/utils/kubectl "https://dl.k8s.io/release/v1.32.0/bin/darwin/arm64/kubectl"
chmod 755 $HOME/opt/utils/kubectl
git clone git@github.com:cfedersp/stepwise-k8s.git  
cd ubuntu-utm-vms  
./host-prep/download-keys.sh  
```

# Create a base linux VM:
Download ARM Image to your host:  
[Ubuntu Server ISO Download](https://ubuntu.com/download/server/arm)  
If you have an ISO, in UTM, select Virtualize, then browse to the ISO and select your machine settings.  
Specify share dir: $PROJECTS_DIR/stepwise-k8s/ubuntu-utm-vms  
Start the Created VM and Select "Install or Try Ubuntu" or wait for the countdown to install Ubuntu.  
Follow OS installation steps, being sure to include:
* Install SSH Server
* Import SSH key
* No snaps are necessary  
* Dont install a firewall for now

Then stop the VM  
Delete the USB drive so the bootloader will not stop for a prompt.  
Start the VM, noting the IP Address printed after login
Delete the contents of /etc/machine-id but dont delete the file.  

Stop using the VM display other than getting the ip.

# Create a base kubernetes VM:
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
Shutdown the VM.

# Setup Master
Clone your base VM, give it a random mac, add 100G NVMe and a new name.  
Wait a couple minutes for UTM to finish copying.  
Start the VM.  
Change hostname:  
```
sudo /usr/share/host/vm-prep/set-hostname-clear-mid-reboot.sh master  
```
Create Volume Group for application data:
```
sudo /usr/share/host/vm-prep/format-logical-drive.sh nvme0n1 app-data
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
Create Volume Group for application data:
```
sudo /usr/share/host/vm-prep/format-logical-drive.sh nvme0n1 app-data
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

# Verify cluster access:
Copy the keys required by CLI to the preferred location:  
From your HOST Mac, dir: $PROJECTS_DIR/stepwise-k8s/ubuntu-utm-vms  
```
cp guest/generated/admin.conf ~/.kube/config
kubectl get nodes
```
# Install a Storage Controller
Create a new Storage Class for the OpenEBS provisioner, and using the "app-data" Volume Group previously created on each node.  
Install the chart, but give values so loki doesn't use such a large disk.  
Check its components start successfully  
```
kubectl apply -f guest/manifests/static/lvm-sc.yaml 
helm install openebs --namespace openebs openebs/openebs --create-namespace --values guest/manifests/static/openebs-disable-mayastor.yaml
kubectl get pods -n openebs
```

# Install Kafka
Not clear how to use KRaft NodePools with our storage configuration - set default sc? Use ZK for now.
```
kubectl apply -f guest/manifests/static/kafka-cluster.yaml -n kafka
```

# Validate Kafka
Publish + Consume msgs
kubectl exec -it my-cluster-kafka-0 -n kafka -- /opt/kafka/bin/kafka-console-producer.sh --topic DEMO 
kubectl exec -it my-cluster-kafka-0 -n kafka -- /opt/kafka/bin/kafka-console-consumer.sh --topic MINIO-BUCKET-NOTIFICATIONS --bootstrap-server localhost:9092 --from-beginning
kubectl exec -it my-cluster-kafka-0 -n kafka -- /opt/kafka/bin/kafka-console-consumer.sh --topic MINIO-BUCKET-NOTIFICATIONS --bootstrap-server my-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092


kubectl exec -it my-cluster-kafka-0 -n kafka -- /bin/bash

./bin/kafka-topics.sh --create --topic DEMO --bootstrap-server localhost:9092
./bin/kafka-console-producer.sh --topic DEMO --bootstrap-server localhost:9092
./bin/kafka-console-consumer.sh --topic DEMO --bootstrap-server localhost:9092 --from-beginning


..or..

-- DOESN'T WORK
-- kubectl run kafka-producer -it --image=bitnami/kafka --restart=Never -- kafka-console-producer.sh --bootstrap-server my-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092 --topic MY-DEMO

-- kubectl run kafka-consumer -it --image=bitnami/kafka --restart=Never -- kafka-console-consumer.sh --bootstrap-server my-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092 --topic MY-DEMO --from-beginning

# Install an Object Store
We need to specify the kafka brokers, so we'll specify the root credentials while we're at it.  
Future task: setup external identity provider so we dont have to handle user credentials here.
The secret must contain key 'config.env', containing export or set commands.


```
helm repo add minio-operator https://operator.min.io
helm install --namespace minio-operator --create-namespace operator minio-operator/operator
kubectl get all -n minio-operator
kubectl create ns ledgerbadger-prod
MINIOVARS=$(echo 'export MINIO_NOTIFY_KAFKA_ENABLE_PRIMARY="on"\nexport MINIO_NOTIFY_KAFKA_BROKERS_PRIMARY="my-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092"\nexport MINIO_NOTIFY_KAFKA_TOPIC_PRIMARY="MINIO-BUCKET-NOTIFICATIONS"\nexport MINIO_ROOT_USER="minio"\nexport MINIO_ROOT_PASSWORD="minio123"')
kubectl create secret generic myminio-env -n ledgerbadger-prod --from-literal=config.env=$MINIOVARS

helm install --namespace ledgerbadger-prod --values guest/helm-values/minio-tenant.yaml ledgerbadger-prod minio-operator/tenant

```

# Upgrade the Object Store Configuration ???
Make changes to tenant config without deleting and re-creating it

# Inspect and Delete
In case you want to start over
```
kubectl get pods -n ledgerbadger-prod
helm list -n ledgerbadger-prod
kubectl get tenant -n ledgerbadger-prod
helm uninstall -n ledgerbadger-prod ledgerbadger-prod
kubectl get pods -n ledgerbadger-prod
```

# MinIO Validation
-- Install a MinIO Client: kubectl run minio-client --image=bitnami/minio-client --restart=Never

## Show Server Configuration

mc alias set myminio https://minio.ledgerbadger-prod.svc.cluster.local/  minio minio123
mc admin info --json myminio

## Basic Bucket Operations
Bucket names are always lower case

mc config host add myminio https://minio.ledgerbadger-prod.svc.cluster.local/  minio minio123
mc mb --with-lock myminio/charliedemo
mc ls myminio

Now subscribe to Bucket Notifications:
Kafka topic names are grouped within a set of multiple configuration properties. 
When subscribing to events, we dont specify the kafka topic, we specify the configuration set *identifier* within an ARN.

Reference:
https://min.io/docs/minio/linux/administration/monitoring/publish-events-to-kafka.html

First make some test data available to your client
-- minio pods dont have tar
-- kubectl cp --disable-compression ~/Downloads/blue-tunnel.jpg ledgerbadger-prod/myminio-pool-0-0:/data -c minio 
mc admin info --json myminio
if your Kafka broken env var is suffixed with _PRIMARY, your SQS endpoint is arn:minio:sqs::PRIMARY:kafka

mc admin config get myminio notify_kafka
mc admin config set myminio/ notify_kafka:PRIMARY tls_skip_verify="on" 
mc admin service restart myminio/
mc event add myminio/charliedemo arn:minio:sqs::PRIMARY:kafka 
mc event list myminio/charliedemo


kubectl exec -it my-cluster-kafka-0 -n kafka -- /bin/bash
./bin/kafka-console-consumer.sh --topic DEMO --bootstrap-server localhost:9092 --from-beginning


mc cp /var/log/hawkey.log myminio/charliedemo/initial/

{
    "EventName": "s3:ObjectCreated:Put",
    "Key": "charliedemo/initial/hawkey.log",
    "Records": [
        {
            "eventVersion": "2.0",
            "eventSource": "minio:s3",
            "awsRegion": "",
            "eventTime": "2025-01-23T14:52:39.116Z",
            "eventName": "s3:ObjectCreated:Put",
            "userIdentity": {
                "principalId": "minio"
            },
            "requestParameters": {
                "principalId": "minio",
                "region": "",
                "sourceIPAddress": "10.85.1.1"
            },
            "responseElements": {
                "x-amz-id-2": "8983154828492820730e147e9ebf4e4e4376e279602e167e33c127a95b20d433",
                "x-amz-request-id": "181D59F971094A02",
                "x-minio-deployment-id": "7d9e7f32-469b-4fe9-8258-19c6b1900f69",
                "x-minio-origin-endpoint": "https://minio.ledgerbadger-prod.svc.cluster.local"
            },
            "s3": {
                "s3SchemaVersion": "1.0",
                "configurationId": "Config",
                "bucket": {
                    "name": "charliedemo",
                    "ownerIdentity": {
                        "principalId": "minio"
                    },
                    "arn": "arn:aws:s3:::charliedemo"
                },
                "object": {
                    "key": "initial%2Fhawkey.log",
                    "size": 180,
                    "eTag": "102f9a14b119807dcd625240e8dead21",
                    "contentType": "text/plain",
                    "userMetadata": {
                        "content-type": "text/plain"
                    },
                    "versionId": "106eb077-2b1b-453a-8049-5631f24a83ed",
                    "sequencer": "181D59F9710A958D"
                }
            },
            "source": {
                "host": "10.85.1.1",
                "port": "",
                "userAgent": "MinIO (linux; arm64) minio-go/v7.0.77 mc/RELEASE.2024-10-02T08-27-28Z"
            }
        }
    ]
}

-p --event post,put,delete
s3:ObjectCreated:Post,s3:ObjectCreated:Put,s3:ObjectCreated:Delete