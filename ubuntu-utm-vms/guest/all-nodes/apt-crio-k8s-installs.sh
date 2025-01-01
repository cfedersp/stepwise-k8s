#!/bin/bash
set -e -x

apt install net-tools parted lvm2 netcat-openbsd zip git apt-transport-https ca-certificates curl gnupg2 software-properties-common jo linux-modules-extra-$(uname -r) -y
KUBERNETES_VERSION=1.28
CRIO_VERSION=1.28.2

cat $(dirname $0)/../../host-prep/keys/crio/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
cat $(dirname $0)/../../host-prep/keys/kubernetes/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install kubelet kubeadm kubectl -y
apt-mark hold kubelet kubeadm kubectl

apt-get install cri-o cri-tools -y

swapoff -a
modprobe overlay
modprobe br_netfilter
modprobe nf_conntrack
modprobe nvme-tcp
cp /etc/fstab /etc/fstab.orig
grep -v swap /etc/fstab.orig > /etc/fstab

sysctl --system
echo "net.netfilter.nf_conntrack_max = 131072" >> /etc/sysctl.conf
echo "net.nf_conntrack_max = 131072" >> /etc/sysctl.conf
printf "overlay\nbr_netfilter\nnf_conntrack\n" > /etc/modules-load.d/kubernetes.conf
printf "net.bridge.bridge-nf-call-iptables  = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\nnet.ipv4.ip_forward                 = 1" > /etc/sysctl.d/kubernetes.conf
echo 'nvme-tcp' | sudo tee -a /etc/modules-load.d/microk8s-mayastor.conf
##  cp -r /etc/crio/crio.conf.d /etc/crio/crio.conf.d.orig

sysctl --system
systemctl start crio.service
systemctl enable crio.service

kubeadm config images pull

printf "NODE_NAME=$(hostname)" > init.env
