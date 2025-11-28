#!/bin/bash

KUBERNETES_VERSION=$1
KUBELET_VERSION=$2
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring-$KUBERNETES_VERSION.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring-$KUBERNETES_VERSION.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update

apt-mark unhold kubelet
apt-get upgrade -y kubelet=${KUBELET_VERSION}
apt-mark hold kubelet
systemctl restart kubelet