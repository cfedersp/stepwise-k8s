#!/bin/bash

INITIALDIR=$(dirname 0)
BASEDIR=$INITIALDIR/charts
mkdir -p $BASEDIR
cd $BASEDIR

echo `pwd`

k8sImages=$(docker image ls --filter=reference='registry.k8s.io/sig-storage/*' --format '{{.Repository}}:{{.Tag}}')

MANIFESTDIR=$INITIALDIR/../guest/manifests/static/

cd host-prep/originals/charts
helm pull grafana/loki
tar -xzf loki*

helm pull minio-operator/operator
tar -xzf operator-*
mv operator minio-operator

cd ../../../