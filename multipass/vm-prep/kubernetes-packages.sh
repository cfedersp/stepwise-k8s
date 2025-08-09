#!/bin/bash
set -e -x

KUBERNETES_VERSION=1.32
# CRIO_VERSION=1.32.6

cp /usr/share/host/host-prep/keys/crio/cri-o-apt-keyring.gpg /etc/apt/keyrings/
cp /usr/share/host/host-prep/keys/kubernetes/kubernetes-apt-keyring.gpg /etc/apt/keyrings/

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" > /etc/apt/sources.list.d/cri-o.list
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install kubelet=1.32.0-1.1 kubeadm=1.32.0-1.1 kubectl=1.32.0-1.1 -y

apt-get install cri-o cri-tools -y
apt-mark hold kubelet kubeadm kubectl cri-o cri-tools

swapoff -a
modprobe overlay
modprobe br_netfilter
modprobe nf_conntrack
cp /etc/fstab /etc/fstab.orig
grep -v swap /etc/fstab.orig > /etc/fstab

sysctl --system
echo "net.netfilter.nf_conntrack_max = 131072" >> /etc/sysctl.conf
echo "net.nf_conntrack_max = 131072" >> /etc/sysctl.conf
printf "overlay\nbr_netfilter\nnf_conntrack\n" > /etc/modules-load.d/kubernetes.conf
printf "net.bridge.bridge-nf-call-iptables  = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward                 = 1" > /etc/sysctl.d/kubernetes.conf
##  cp -r /etc/crio/crio.conf.d /etc/crio/crio.conf.d.orig

sysctl --system
systemctl start crio.service
systemctl enable crio.service

kubeadm config images pull

