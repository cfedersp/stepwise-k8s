#!/bin/bash

# MinIO tenant values
curl -sLo guest/helm-values/minio-tenant-orig.yaml https://raw.githubusercontent.com/minio/operator/master/helm/tenant/values.yaml

# haven't gotten NodePools to work yet. All KRaft COs use NodePools
# CO_FILE='guest/manifests/static/kafka-kraft-cluster.yaml'
# curl -L -o $CO_FILE 'https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/refs/tags/0.45.0/examples/kafka/kraft/kafka-with-dual-role-nodes.yaml'
CO_FILE='guest/manifests/static/kafka-cluster-orig.yaml'
curl -L -o $CO_FILE 'https://raw.githubusercontent.com/strimzi/strimzi-kafka-operator/refs/tags/0.45.0/examples/kafka/kafka-jbod.yaml'

echo "Now edit $CO_FILE, adding .spec.storage.volumes.class under KafkaNodePool, and update the size"