#!/bin/bash

INITIAL_DIR=$(dirname 0)
REFERENCE_DIR=$INITIALDIR/host-prep/original-reference/

mkdir -p $REFERENCE_DIR/charts $REFERENCE_DIR/gitrepos
cd $REFERENCE_DIR/charts

echo `pwd`

k8sImages=$(docker image ls --filter=reference='registry.k8s.io/sig-storage/*' --format '{{.Repository}}:{{.Tag}}')

MANIFEST_DIR=$INITIAL_DIR/../guest/manifests/static/

cd host-prep/original-reference/charts
helm pull grafana/loki
tar -xzf loki*

helm pull minio-operator/operator
tar -xzf operator-*
mv operator minio-operator

helm pull jetstack/cert-manager
tar -xzf cert-manager-*

cd ../gitrepos/
git clone https://github.com/osixia/docker-openldap.git
cp docker-openldap/example/kubernetes/using-secrets/gce-statefullset.yaml guest/manifests/static/ldap-ss.yaml
cp docker-openldap/example/kubernetes/using-secrets/environment/my-env.yaml.example guest/manifests/static/ldap-env.yaml
cp docker-openldap/example/kubernetes/using-secrets/environment/my-env.startup.yaml.example guest/manifests/static/ldap-env.startup.yaml

cd ../../../