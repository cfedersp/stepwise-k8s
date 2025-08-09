#!/bin/bash

KUBERNETES_VERSION=$1
BASEDIR=keys
mkdir -p $BASEDIR/crio
mkdir -p $BASEDIR/kubernetes

# curl -L -o $BASEDIR/crio/Prerelease.key  https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key
curl -L -o $BASEDIR/crio/Release.key  https://pkgs.k8s.io/addons:/cri-o:/${KUBERNETES_VERSION}:/main/deb/Release.key
curl -L -o $BASEDIR/kubernetes/Release.key https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key
# cat $BASEDIR/crio/Prerelease.key | gpg --dearmor -o $BASEDIR/crio/cri-o-apt-keyring-prerelease.gpg
cat $BASEDIR/crio/Release.key | gpg --dearmor -o $BASEDIR/crio/cri-o-apt-keyring-release.gpg

cat $BASEDIR/kubernetes/Release.key | gpg --dearmor -o $BASEDIR/kubernetes/kubernetes-apt-keyring.gpg