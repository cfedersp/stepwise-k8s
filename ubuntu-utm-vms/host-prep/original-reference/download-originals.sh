#!/bin/bash

# Get ready to pull some charts
mkdir -p host-prep/original-reference/charts; 
cd host-prep/original-reference/charts; 

# Add repos
helm repo add openebs https://openebs.github.io/openebs
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo add hashicorp https://helm.releases.hashicorp.com

helm repo update

# OpenEBS
helm pull openebs/openebs
tar -xzf openebs-*

# Vault CSI - This is built-in to the vault chart
# helm pull secrets-store-csi-driver/secrets-store-csi-driver
# tar -xzf secrets-store-csi-driver-*
# cp secrets-store-csi-driver/values.yaml ../../../guest/helm-values/secrets-store-csi-driver-orig.yaml

# Vault Chart and values
helm pull hashicorp/vault; 
tar -xzf vault-*; 
cp vault/values.yaml ../../../guest/helm-values/vault-orig.yaml; 


# Kafka
curl -L -o $MANIFESTDIR/strimzi-crds-operators.yaml https://strimzi.io/install/latest?namespace=mydemo
curl -L -o $MANIFESTDIR/strimzi-kafka.yaml  https://strimzi.io/examples/latest/kafka/kafka-persistent-single.yaml


# MinIO tenant values
helm pull minio-operator/operator
tar -xzf operator-*
mv operator minio-operator
cp minio-operator/values.yaml guest/helm-values/minio-tenant-orig.yaml
# curl -sLo guest/helm-values/minio-tenant-orig.yaml https://raw.githubusercontent.com/minio/operator/master/helm/tenant/values.yaml

# Done with charts
cd ../../.. 

mkdir -p guest/all-nodes/downloads
curl -L -o guest/all-nodes/downloads/calico https://github.com/projectcalico/cni-plugin/releases/download/v3.14.0/calico-arm64
curl -L -o guest/all-nodes/downloads/calico-ipam https://github.com/projectcalico/cni-plugin/releases/download/v3.14.0/calico-ipam-arm64

# SSLScan
git clone git@github.com:rbsec/sslscan.git
cd sslscan
make static
cp sslscan ~/opt/utils/


# haven't gotten NodePools to work yet. All KRaft COs use NodePools
# CO_FILE='guest/manifests/static/kafka-kraft-cluster.yaml'
# curl -L -o $CO_FILE 'https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/refs/tags/0.45.0/examples/kafka/kraft/kafka-with-dual-role-nodes.yaml'
CO_FILE='guest/manifests/static/kafka-cluster-orig.yaml'
curl -L -o $CO_FILE 'https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/refs/tags/0.45.0/examples/kafka/kafka-jbod.yaml'

echo "Now edit $CO_FILE, adding .spec.storage.volumes.class under KafkaNodePool, and update the size"

curl -L -o guest/manifests/static/calico-custom-resources.yaml 'https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/custom-resources.yaml'
