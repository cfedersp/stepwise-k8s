#!/bin/bash

INITIALDIR=$(dirname 0)
BASEDIR=$INITIALDIR/charts
mkdir -p $BASEDIR
cd $BASEDIR

echo `pwd`
git clone git@github.com:alibaba/open-local.git
chmod 775 open-local/hack/community-image-sync.sh
./open-local/hack/community-image-sync.sh

k8sImages=$(docker image ls --filter=reference='registry.k8s.io/sig-storage/*' --format '{{.Repository}}:{{.Tag}}')

MANIFESTDIR=$INITIALDIR/../guest/manifests/static/
curl -L -o $MANIFESTDIR/strimzi-crds-operators.yaml https://strimzi.io/install/latest?namespace=mydemo
curl -L -o $MANIFESTDIR/strimzi-kafka.yaml  https://strimzi.io/examples/latest/kafka/kafka-persistent-single.yaml
