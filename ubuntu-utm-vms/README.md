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
 
# Dictionary:
- Container: isolated process
- Manifest:
- Pod: A group of related containers where 1 is the main process plus some optional support containers that will run on the same CPU. Can exist as a declared descriptor, scheduled to a Node, even though it hasn't started running or have disks attached yet.
- Persistent Volume: A disk attached to a node, usually exposed as an LVM Volume Group.
- Persistent Volume Claim: A request by pod for a logical volume and volume mount into that pod.
- Deployment
- StatefulSet
- Role: Allows a service to interact with Kubernetes, creating or modifying resources.
- Custom Resource Definition: Document Schema that defines custom infrastructure and infrastructure behavior. 
- Custom Resource or Custom Object: An instance of CRD document
- Operator: An admin service that watches changes in Custom Resources and acts upon those changes until the cluster is in the desired state.
An operator's initial state includes no resources until a Custom Resource is created. Operators have a Role that allow them to create configMaps or Secrets that other components depend on. They orchestrate software runtimes by manaaging complex inter-dependencies for you.

# Process Overview:
## Strategize:
Security:
Keys, Passwords and mTLS Client Certs must be stored in Vault and mounted directly into pods with reduced permissions.
Root Keys can be(is automatically) stored in Vault, but must be stored outside the VM, perhaps in cold(er) storage with restricted permissions.
Public Keys, CA Certificates and TLS Certificates can be kubernetes secrets. Storing them in Vault is not necessary but nice to keep inventory in 1 place.

Signing keys: ??

Temporary Tokens/Dynamic Secrets: 
https://developer.hashicorp.com/vault/docs/concepts/lease
These are represented in Vault as metadata called a *Lease*. leases can be renewed or revoked. When a token's TTL expires, it is revoked.
A revoked token causes all tokens generated from that token to also get revoked.
Queries for dynamic tokens include the durable Lease ID in the response.
Where can we use temporary tokens? 

Sealing and Unsealing: 
https://developer.hashicorp.com/vault/docs/concepts/seal
Just because an instance is running doesn't allow it to decrypt any data.
it must be authorized with a key that is only kept in memory.
who can do this? At what times is the vault sealed? What does a sealed Vault prevent? How is the root cluster key stored?

Namespace lock:
https://developer.hashicorp.com/vault/docs/concepts/namespace-api-lock
lock a subset of Vault endpoints and all descendents.

Identity:
Vault OIDC: https://developer.hashicorp.com/vault/docs/concepts/oidc-provider

Encryption:

Replication:

Back-ups:

## Prep host:  
Create dir for utils
mkdir -p ~/opt/utils/

Create ~/.kube/ dir for CLI keys  
Install helm and kubectl so we can interact with the cluster once its running.  
Clone this repo  
Download latest crio and kubernetes package keys  
./host-prep/download-originals.sh
Install MINISIGN
https://jedisct1.github.io/minisign/

Install Vualt CLI
curl -sSL --tlsv1.2 -o ~/Downloads/vault_1.18.4_darwin_arm64.zip 'https://releases.hashicorp.com/vault/1.18.4/vault_1.18.4_darwin_arm64.zip'
cd ~/opt/utils; unzip ~/Downloads/vault*

Install KES
https://min.io/docs/kes/cli/
curl -sSL --tlsv1.2 'https://github.com/minio/kes/releases/latest/download/kes-<OS>-<ARCH>' -o ~/opt/utils/kes

chmod 775 ~/opt/utils/kes

Verify the download
curl -sSL --tlsv1.2 "https://github.com/minio/kes/releases/latest/download/kes-$(uname)-$(uname -m).minisig" -o ./kes.minisig
minisign -Vm ./kes -P "RWTx5Zr1tiHQLwG9keckT0c45M3AGeHD6IvimQHpyRywVWGbP1aVSGav"

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
sudo /usr/share/host/vm-prep/set-hostname-clear-mid-reboot.sh worker1  
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
VMs wont be able to reach services, but pods will.
# Pending - persist routes 
https://linuxconfig.org/how-to-add-static-route-with-netplan-on-ubuntu-20-04-focal-fossa-linux
sudo cat /etc/netplan/50-cloud-init.yaml

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
MayaStor replication is only tested on x86-64. If you try it on apple silicon, you need to configure ARM images (loki-stack.loki.initContainers[0].image: cannot be bitnami/shell)
Nodes with replicated storage must be labelled openebs.io/engine=mayastor
-- kubectl label node <node_name> openebs.io/engine=mayastor
Check its components start successfully  
```
kubectl apply -f guest/manifests/static/lvm-sc.yaml 
helm install openebs --namespace openebs openebs/openebs --create-namespace --values guest/manifests/static/openebs-disable-mayastor.yaml
kubectl get pods -n openebs
```

## Note Storage Classes:
openebs-hostpath
- mounts a dir on the VM into the container
- has WaitForFirstConsumer VolumeBindingMode: The Volume controller will wait until the pod scheduler updates a PVC annotation indicating which node
openebs-lvmpv: (bad - I created this without VolumeBindingMode, and it defauled to Immediate)
- provisions a Logical Volume, formats it, and mounts it into the container
- has Immediate VolumeBindingMode
- How is this assigned to a node?

For pod scheduling to work, the SC must be WaitForFirstConsumer? explain

# Inspect OpenEBS
kubectl get ds openebs-lvm-localpv-node -n openebs -o yaml
kubectl get lvmvolume -n openebs

# Install Kafka
Not clear how to use KRaft NodePools with our storage configuration - set default sc? Use ZK for now.
```
kubectl apply -f guest/manifests/static/kafka-cluster.yaml -n kafka
```

## Validate Kafka
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

## Delete Kafka
kubectl get kafka my-cluster -n kafka
kubectl delete kafka my-cluster -n kafka

# Integrate HashiCorp Vault for KMS

## Dictionary:
- Vault
- CSI Driver: The service that exposes secrets as mountable volumes
- SecretProviderClass: Directive to expose a secret as a mountable volume
- Agent Injector: Admission Controller that re-writes pods to include secrets as mounted volumes
- Vault Secrets Operator:
## References:
https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate
https://secrets-store-csi-driver.sigs.k8s.io/getting-started/installation.html
https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

## Generate cert and have kubernetes sign it
https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate
A webserver's TLS cert does not have to be signed by the cluster CA, but vault will 
```
source applications/vault/default-ns-env
export WORKDIR=applications/generated/certs
mkdir -p $WORKDIR/manifests
openssl genrsa -out ${WORKDIR}/vault.key 2048
source applications/default-ns-env VAULT
./applications/create-csr-conf.sh vault > ${WORKDIR}/vault-csr.conf
openssl req -new -key ${WORKDIR}/vault.key -out ${WORKDIR}/vault.csr -config ${WORKDIR}/vault-csr.conf
./applications/gen-csr.sh ledgerbadger-vault ${WORKDIR}/vault.csr > ${WORKDIR}/manifests/vault-csr.yaml
kubectl create -f ${WORKDIR}/manifests/vault-csr.yaml
kubectl get csr
kubectl certificate approve ledgerbadger-vault.svc
kubectl get csr ledgerbadger-vault.svc -o jsonpath='{.status.certificate}' | openssl base64 -d -A -out ${WORKDIR}/vault.crt
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${WORKDIR}/ledgerbadger-vault.ca
openssl x509 -text -noout -in ${WORKDIR}/ledgerbadger-vault.ca
kubectl create secret generic vault-ca \
   -n $VAULT_K8S_NAMESPACE \
   --from-file=vault.ca=${WORKDIR}/ledgerbadger-vault.ca

kubectl create secret generic vault-ha-tls \
   -n $VAULT_K8S_NAMESPACE \
   --from-file=vault.key=${WORKDIR}/vault.key \
   --from-file=vault.crt=${WORKDIR}/vault.crt

```

## NONONO: Install Secrets CSI Driver 
This allows Vault Secrets to be mounted as Volumes ?when a SecretProviderClass is created?
Either install this storage driver or enable the Agent Injector w/ a Service Account bound to the appropriate role - not both.
```
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system
```
## NONONO: Create a SecretProviderClass 

## Install Vault Chart w/o the "Agent Injector" admission controller
https://developer.hashicorp.com/vault/docs/platform/k8s/injector
Note, for Kubernetes 1.24, serviceAccount.createSecret should be false
```
sudo rm applications/generated/cluster-keys.json
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault --values guest/helm-values/vault.yaml 

export INITIAL_VAULT_NODE="vault-0"
kubectl exec $INITIAL_VAULT_NODE -- vault operator init -address "https://$INITIAL_VAULT_NODE.vault-internal.default.svc.cluster.local:8200" -key-shares=1 -key-threshold=1 -format=json > applications/generated/cluster-keys.json

sudo chown root applications/generated/cluster-keys.json
sudo chmod go-rw applications/generated/cluster-keys.json
VAULT_UNSEAL_KEY=$(sudo jq -r ".unseal_keys_b64[]" applications/generated/cluster-keys.json)
kubectl exec $INITIAL_VAULT_NODE -- vault operator unseal -address "https://$INITIAL_VAULT_NODE.vault-internal.default.svc.cluster.local:8200" $VAULT_UNSEAL_KEY
echo "Now have the other instances join the first"

kubectl exec -it vault-1 -- vault operator raft join -address=https://vault-1.vault-internal:8200 -leader-ca-cert="@/etc/ssl/certs/vault.ca" -leader-client-cert="@/vault/userconfig/vault-ha-tls/vault.crt" -leader-client-key="@/vault/userconfig/vault-ha-tls/vault.key" https://vault-0.vault-internal:8200

kubectl exec vault-1 -- vault operator unseal -address "https://vault-1.vault-internal.default.svc.cluster.local:8200" $VAULT_UNSEAL_KEY

kubectl exec -it vault-2 -- vault operator raft join -address=https://vault-2.vault-internal:8200 -leader-ca-cert="@/etc/ssl/certs/vault.ca" -leader-client-cert="@/vault/userconfig/vault-ha-tls/vault.crt" -leader-client-key="@/vault/userconfig/vault-ha-tls/vault.key" https://vault-0.vault-internal:8200

kubectl exec vault-2 -- vault operator unseal -address "https://vault-2.vault-internal.default.svc.cluster.local:8200" $VAULT_UNSEAL_KEY

vault status -address="$VAULT_ADDR"
```

## Didn't work:
retry_join

## Inspect HA Vault
An instance wont appear as a peer until it has been unsealed.
```
export CLUSTER_ROOT_TOKEN=$(sudo cat applications/generated/cluster-keys.json | jq -r ".root_token")
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault login $CLUSTER_ROOT_TOKEN

kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers  -address "https://vault-2.vault-internal.default.svc.cluster.local:8200"
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers  -address "https://vault.default.svc.cluster.local:8200" 
kubectl exec -n $VAULT_K8S_NAMESPACE vault-0 -- vault operator raft list-peers  -address "https://ledgerbadger-vault.default.svc.cluster.local:8200" 



kubectl exec -n $VAULT_K8S_NAMESPACE -it vault-0 -- /bin/sh
vault secrets enable -path=secret - kv-v2 
vault kv put secret/tls/apitest username="apiuser" password="supersecret"
vault kv get secret/tls/apitest
```

## Pending: Browser access to your cluster
https://www.reddit.com/r/MacOS/comments/1fjopdm/something_has_changed_in_sequoia_in_regards_to/
https://kenmoini.com/post/2024/02/adding-trusted-root-certificate-authority/#adding-to-mac-os-x---cli
Install the root CA, having a SAN you want to use to access your local cluster.
Update the /etc/hosts to point the host to a worker IP
Create a NodePort service to expose the port.
Adding the trusted cert to KeyChain allows you to stop entering -ca-cert for all commands.
May need turn off Safe Browsing?
In Chrome Settings, Disable Secure DNS: chrome://settings/security
In System Settings, Privacy & Security -> Network, allow Chrome.
```
kubectl apply -f guest/manifests/static/ledgerbadger-vault-svc.yaml
VAULT_PORT=$(kubectl get svc ledgerbadger-vault -o json | jq -r '.spec.ports[0].nodePort')
VAULT_ADDR="https://ledgerbadger-vault.default.svc.cluster.local:$VAULT_PORT"
vault login -address="$VAULT_ADDR" -ca-cert="applications/generated/certs/ledgerbadger-vault.ca" $CLUSTER_ROOT_TOKEN

echo $VAULT_ADDR/ui
curl -L $VAULT_ADDR/ui
vault operator raft list-peers  -address "$VAULT_ADDR" -ca-cert "applications/generated/certs/ledgerbadger-vault.ca"
vault operator raft list-peers  -address "$VAULT_ADDR" 
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain applications/generated/certs/ledgerbadger-vault.ca
vault operator raft list-peers  -address "$VAULT_ADDR" 

vault auth enable -address "$VAULT_ADDR" userpass 
vault write -address "$VAULT_ADDR" auth/userpass/users/charlie policies=default password=vault@1

```

## Write a secret that becomes a mountable volume
https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-secret-store-driver

Create a secret.
Then create a Vault kubernetes authentication role called 'database' that grants the 'my-app-sa' service account with policy 'internal-app'
Then create a service account for use by a pod that mounts a volume provided by the Vault CSI provider.
The service account does not have a Kubernetes role, but a Vault kubernetes role.
```
kubectl exec -n $VAULT_K8S_NAMESPACE -it vault-0 -- /bin/sh
vault kv put -address "$VAULT_ADDR" secret/db-pass password="db-secret-password"
vault auth enable -address "$VAULT_ADDR" kubernetes
export KUBERNETES_PORT_443_TCP_ADDR="192.168.64.7"
vault write -address "$VAULT_ADDR" auth/kubernetes/config kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

vault secrets enable -address "$VAULT_ADDR" -version=1 kv
vault policy write  -address "$VAULT_ADDR" internal-app - <<EOF
path "secret/data/db-pass" {
  capabilities = ["read"]
}
EOF

vault write -address "https://vault-0.vault-internal.default.svc.cluster.local:8200" \
auth/kubernetes/role/database \
    bound_service_account_names=my-apps-sa \
    bound_service_account_namespaces=default \
    policies=internal-app \
    ttl=20m 

vault list -address "$VAULT_ADDR" auth/kubernetes/role
kubectl apply -f guest/manifests/static/vault-database-spc.yaml

kubectl create serviceaccount my-apps-sa
kubectl apply -f guest/manifests/static/secret-mounting-pod.yaml 
kubectl exec webapp -- cat /mnt/secrets-store/db-password
```

## Enable KES integraation
https://min.io/docs/kes/cli/
https://min.io/docs/kes/integrations/hashicorp-vault-keystore/
https://support.hashicorp.com/hc/en-us/articles/4404389946387-Kubernetes-auth-method-Permission-Denied-error
```


vault policy write  -address "$VAULT_ADDR" minio-ledgerbadger-kes - <<EOF
path "kv/*" {
   capabilities = [ "create", "read", "delete", "list" ]
}
EOF

vault write -address "$VAULT_ADDR" \
auth/kubernetes/role/minio-ledgerbadger-kes-role \
    bound_service_account_names=minio-kes-sa \
    bound_service_account_namespaces=ledgerbadger-prod \
    policies=minio-ledgerbadger-kes \
    ttl=20m 


kubectl create serviceaccount minio-kes-sa -n ledgerbadger-prod

show issuer:
openssl x509 -in public.crt -noout -text -sha256
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --d)
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}') 
TOKEN_REVIEW_JWT=$(kubectl get secret vault-sa-token -o go-template='{{ .data.token }}' | base64 --decode) 
vault write -address "$VAULT_ADDR" auth/kubernetes/config issuer="kubernetes" kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" 
Shouldn't neeed this because cluster CA is already trusted?
kubernetes_ca_cert="$KUBE_CA_CERT" 
Shouldn't need these because sa is configured for Vault:
vault write -address "$VAULT_ADDR" auth/kubernetes/config issuer="kubernetes" kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" disable_local_ca_jwt="true" token_reviewer_jwt="$TOKEN_REVIEW_JWT"

vault read -address "$VAULT_ADDR" auth/kubernetes/config

kubectl apply -f guest/manifests/static/vault-sa.yaml
```

## Pending: 
enable audit storage, validate UI, enable csi provider or secrets operator
impl ingress controller and enable ingress? how is access controlled?

## DO NOT DO THIS: Install Vault Secrets Operator
CSI is better than native secrets
Exposes Vault Secrets as Kubernetes Secrets
https://developer.hashicorp.com/vault/docs/platform/k8s/vso/installation
```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install --version 0.9.1 vault-secrets-operator hashicorp/vault-secrets-operator
```


# Delete Vault + Volumes
```
helm uninstall vault hashicorp/vault
kubectl delete pvc data-vault-0
```

## Validate Vault - Pending
certs?
validation steps?

# Pending: stop using vault.ca as ledgerbadger-vault.ca: client cert should be signed by Vault.ca. Can be a copy for 1 way trust, but better to be a signed intermediate cert for 2 way, revocable trust.

# Pending: minio with kes/Vault integration using kubernetes service account
https://github.com/minio/kes
https://min.io/docs/kes/integrations/hashicorp-vault-keystore/
https://min.io/docs/minio/kubernetes/gke/reference/operator-crd.html
Kubernetes service account means we dont have to configure mTLS.
create and configure kes service account - tenant.kes.serviceAccountName? yes. done
create TLS certs for kes. If TLS certs dont use CA trusted by Vault (kubernetes), then multiple CAs must be mounted under /etc/ssl/certs/.
Possible to use kes identity, but the API Key and identity are not needed.
create kes identity for minio. It is its own authentication mechanism, not mTLS, does not use kubernetes, so does not need to be same name as service account.
Add the kes policy to kes config. It refers to kes endpoints, not vault endpoints. Either set the policy w/ minio indentity ..OR.. give minio admin access by setting .root to the minio identity
later: create kes identity for CLI access, will be set in .admin.identity
install kes TLS certs as kubernetes secret. done
install minio kes identity cert as kubernetes secret. done

prefix: keyspace for the tenant. should be reflected in the access policy.
what are keys? transit?
How does the mounted secret become env var?

mount the CA secret into kes  server in minio-tenant.yaml - done by chart - we simply mention the secret
mount the TLS secret into kes server in minio-tenant.yaml - done by chart - we simply mention the secret
mount the minio kes identity?
specify tls certs in kes config. half done?
specify tls certs in kes-vault config. half done?
If CSI is invoking Vault, why is kubernetes the CA?
create Kubernetes Vault Policy + Role that allows access to ledgerbadger secrets. done
create minio service account? done
configure kes

Using kes, create minio client cert. This is a self-signed cert, but its not x509 TLS cert. It cannot be generated or parsed fully by openssl. It does not need to be signed by any CA. The generated key, cert, API key and fingerprint can be stored in Vault, but dont need to be.
configure its identity in the tenant.kes.admin.identity. The key and cert get configured in minio, not vault or minio's kes config.
mount the minio client cert secret in minio tenant additionalvolumes.
configure the minio client cert in minio. note the API KEY: kes:v1:AJ9e6sX9eJiAta8jtGjK1ngRpL1JTBIwcxN6WswNVGYP
create the default encryption key (EK)? yes: "my-minio-key"

what is path to tls cert files?
what is MINIO_KES_IDENTITY?
what is KMS key name: my-minio-key? is this a default key for the tenant when one is not specified?
deploy minio tenant

```
source applications/default-ns-env kes
export WORKDIR=applications/generated/certs
openssl genrsa -out ${WORKDIR}/kes.key 2048
./applications/create-csr-conf.sh ledgerbadger-kes > ${WORKDIR}/kes-csr.conf
openssl req -new -key ${WORKDIR}/kes.key -out ${WORKDIR}/kes.csr -config ${WORKDIR}/kes-csr.conf
./applications/gen-csr.sh ledgerbadger-kes ${WORKDIR}/kes.csr > ${WORKDIR}/manifests/kes-csr.yaml
kubectl create -f ${WORKDIR}/manifests/kes-csr.yaml
kubectl get csr
kubectl certificate approve ledgerbadger-kes.svc
kubectl get csr ledgerbadger-kes.svc -o jsonpath='{.status.certificate}' | openssl base64 -d -A -out ${WORKDIR}/kes.crt
DONT! This is the cluster root ca, which is already a secret in every namespace:
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${WORKDIR}/ledgerbadger-kes.ca
openssl x509 -text -noout -in ${WORKDIR}/ledgerbadger-kes.ca

kubectl create secret tls  kes-tls -n ledgerbadger-prod --cert ${WORKDIR}/kes.crt --key ${WORKDIR}/kes.key

kubectl create secret generic kes-tls \
   -n ledgerbadger-prod \
   --from-file=kes.key=${WORKDIR}/kes.key \
   --from-file=kes.crt=${WORKDIR}/kes.crt


kes identity new --key=${WORKDIR}/minio-ledgerbadger-prod.key --cert=${WORKDIR}/minio-ledgerbadger-prod.crt minio-ledgerbadger-prod
mkdir -p ${WORKDIR}/kesadmin
kes identity new --key=${WORKDIR}/kesadmin/charlie.key --cert=${WORKDIR}/kesadmin/charlie.crt charlie
API: kes:v1:APyZE/WnPqohCZQW+gld1xjEdwEADNfuOPLr2+gtMc8u
ID: 70d80035b100a05d9fa9b2059ba1b78bd404bea9730daedcbbc705534d1515d2

kubectl create secret generic minio-ledgerbadger-prod-kes-cred \
   -n ledgerbadger-prod \
   --from-file=minio-kes.key=${WORKDIR}/minio-ledgerbadger-prod.key \
   --from-file=minio-kes.crt=${WORKDIR}/minio-ledgerbadger-prod.crt

helm install --namespace ledgerbadger-prod --values guest/helm-values/minio-tenant.yaml ledgerbadger-prod minio-operator/tenant
helm uninstall ledgerbadger-prod -n ledgerbadger-prod
```
kes.configuration.keystore.vault:
tls:   
            key: /tmp/kes/server.key   # Path to the TLS private key
            cert: /tmp/kes/server.crt # Path to the TLS certificate     
            ca: ./vault.ca
kes logs:
WARNING: '--auth' flag is deprecated and no longer honored. Specify the client certificate verification in the config file
Error: kesconf: invalid tls config: no private key
fixed by removing cert config from kes. DONT create certs for kes, only identities!
next error:
Error: kesconf: failed to read vault kubernetes JWT from '/var/run/secrets/kubernetes.io/serviceaccount': read /var/run/secrets/kubernetes.io/serviceaccount: is a directory
vault url had http
next error:
kes:
Error: Put "https://vault.default.svc.cluster.local:8200/v1/auth/kubernetes/login": tls: failed to verify certificate: x509: certificate signed by unknown authority
vault:
2025-02-04T18:47:18.858Z [INFO]  http: TLS handshake error from 10.85.6.18:37898: remote error: tls: bad certificate

added clientCertSecret: my-clustercluster-ca, tls.ca: public.crt to tenant config

phony CA gives:
Error: failed to read TLS CA certificates: stat /tmp/kes/public.crtxxx: no such file or directory

check cert chain:
kubectl get secret my-cluster-cluster-ca -n ledgerbadger-prod -o json | jq -r '.data."public.crt"' | base64 -d >  public.crt
kubectl get csr myminio-kes-ledgerbadger-prod-csr -n ledgerbadger-prod -o json | jq -r '.status.certificate' | base64 -d > autokes.crt
openssl verify -CAfile public.crt applications/generated/certs/vault.crt
openssl verify -CAfile public.crt autokes.crt

kes tls server config isn't necessarily used as the client cert to Vault. where are the Vault credentials?

mTLS worked.
next error:
Error: Error making API request.

Namespace: default
URL: PUT https://vault.default.svc.cluster.local:8200/v1/auth/kubernetes/login
Code: 400. Errors:

* invalid role name "default"

Fixed role name.
KES successfully authenticated.
Next error:
Error: Error making API request.

Namespace: default
URL: PUT https://vault.default.svc.cluster.local:8200/v1/auth/kubernetes/login
Code: 500. Errors:

* could not load backend configuration

enabled kubernetes and wrote kubernetes api url to vault config
next error:
Namespace: default
URL: PUT https://vault.default.svc.cluster.local:8200/v1/auth/kubernetes/login
Code: 403. Errors:

* namespace not authorized

KES started
next error:
minio:
FATAL Failed to connect to KMS: failed to generate data key with KMS key: failed to read key
vault:
 Error while dialing: tls: failed to verify certificate: x509: certificate has expired or is not yet valid: current time 2025-02-05T03:27:10Z is before 2025-02-05T04:33:29Z\""


not tried
openssl s_client -connect host:443 \
   -cert cert_and_key.pem \
   -key cert_and_key.pem  \
   -state -debug


kes:
Error: Put "https://vault.default.svc.cluster.local:8200/v1/auth/kubernetes/login": tls: failed to verify certificate: x509: certificate signed by unknown authority
vault:
2025-02-04T19:26:52.855Z [INFO]  http: TLS handshake error from 192.168.64.18:57674: remote error: tls: bad certificate


  kubectl get secret kes-configuration -n ledgerbadger-prod -o json | jq -r '.data."server-config.yaml"' | base64 -d


kv engine and version were wrong! need to redo the vault role+policy for v1
DONT: Generate a client cert for kes
```
vault secrets enable pki
vault write -field=certificate pki/root/generate/internal \
        common_name="dc1.consul" \
        ttl=87600h > CA_cert.crt
```

# Install an Object Store
We need to specify the kafka brokers, so we'll specify the root credentials while we're at it.  
Future task: setup external identity provider so we dont have to handle user credentials here.
The MinIO config secret must contain key 'config.env', containing export or set commands.

Also, we copy the kafka root cert into a secret and specify that secret and type in externalCaCertSecret 
so minio pods will trust it.

## Demonstrate the vulnerability of unprotected files
From a VM running an openebs-provisioned logical volume, you can cat /dev/dm-0 special block files and potentially extract data.
This is left as an exersize for the reader.

## References:
https://min.io/docs/minio/kubernetes/upstream/operations/network-encryption.html#id4

```
helm repo add minio-operator https://operator.min.io
helm install --namespace minio-operator --create-namespace operator minio-operator/operator
kubectl get all -n minio-operator
kubectl create ns ledgerbadger-prod
MINIOVARS=$(echo 'export MINIO_NOTIFY_KAFKA_ENABLE_PRIMARY="on"\nexport MINIO_NOTIFY_KAFKA_BROKERS_PRIMARY="my-cluster-kafka-bootstrap.kafka.svc.cluster.local:9092"\nexport MINIO_NOTIFY_KAFKA_TOPIC_PRIMARY="MINIO-BUCKET-NOTIFICATIONS"\nexport MINIO_ROOT_USER="minio"\nexport MINIO_ROOT_PASSWORD="minio123"\nexport MINIO_KMS_KES_CERT_FILE="/kes/minio-kes.crt"\nexport MINIO_KMS_KES_KEY_FILE="/kes/minio-kes.key"\nexport MINIO_KMS_KES_KEY_NAME="minio-ledgerbadger-prod"')

kubectl create secret generic myminio-env -n ledgerbadger-prod --from-literal=config.env=$MINIOVARS

ROOTCACERT=$(kubectl get cm kube-root-ca.crt -n kafka -o json | jq -r '.data."ca.crt"')
kubectl create secret  my-cluster-cluster-ca -n ledgerbadger-prod --cert $ROOTCACERT
kubectl create secret generic my-cluster-cluster-ca -n ledgerbadger-prod --from-literal=public.crt=$ROOTCACERT

helm install --namespace ledgerbadger-prod --values guest/helm-values/minio-tenant.yaml ledgerbadger-prod minio-operator/tenant

```

# Pending: specify minio env in a secret yaml, not from cli
See bottom of tenant for an example.

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
Use minio ndode: kubectl exec -it myminio-pool-0-0 -n ledgerbadger-prod -- /bin/bash
Encrypt a bucket with an external KMS Key
```
mc encrypt set sse-kms EXTERNALKEY myminio/charliedemo
```
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
mc admin config set myminio/ notify_kafka:PRIMARY tls_skip_verify="off" 
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

# More Notes:
PodNodeSelector: https://stackoverflow.com/questions/52487333/how-to-assign-a-namespace-to-certain-nodes
-p --event post,put,delete
s3:ObjectCreated:Post,s3:ObjectCreated:Put,s3:ObjectCreated:Delete


