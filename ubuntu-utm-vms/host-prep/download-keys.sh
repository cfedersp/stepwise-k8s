#!/bin/bash

BASEDIR=$(dirname $0)/keys
mkdir -p $BASEDIR/crio
mkdir -p $BASEDIR/kubernetes

curl -L -o $BASEDIR/crio/Release.key  https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key
curl -L -o $BASEDIR/kubernetes/Release.key https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key
