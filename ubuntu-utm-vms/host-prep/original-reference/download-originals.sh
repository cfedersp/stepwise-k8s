#!/bin/bash

# Get ready to pull some charts
mkdir -p host-prep/original-reference/charts; 
cd host-prep/original-reference/charts; 

# Vault CSI - Pull this so we can see whats in it, but right now we dont have anything to improve
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm pull secrets-store-csi-driver/secrets-store-csi-driver
tar -xzf secrets-store-csi-driver-*
cp secrets-store-csi-driver/values.yaml ../../../guest/helm-values/secrets-store-csi-driver-orig.yaml

# Vault Chart and values
helm repo add hashicorp https://helm.releases.hashicorp.com
helm pull hashicorp/vault; 
tar -xzf vault-*; 
cp vault/values.yaml ../../../guest/helm-values/vault-orig.yaml; 
cd ../../.. 

# MinIO tenant values
curl -sLo guest/helm-values/minio-tenant-orig.yaml https://raw.githubusercontent.com/minio/operator/master/helm/tenant/values.yaml

# haven't gotten NodePools to work yet. All KRaft COs use NodePools
# CO_FILE='guest/manifests/static/kafka-kraft-cluster.yaml'
# curl -L -o $CO_FILE 'https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/refs/tags/0.45.0/examples/kafka/kraft/kafka-with-dual-role-nodes.yaml'
CO_FILE='guest/manifests/static/kafka-cluster-orig.yaml'
curl -L -o $CO_FILE 'https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/refs/tags/0.45.0/examples/kafka/kafka-jbod.yaml'

echo "Now edit $CO_FILE, adding .spec.storage.volumes.class under KafkaNodePool, and update the size"