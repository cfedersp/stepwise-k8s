#!/bin/bash
set -e -x
IP_ADDRESS=$(ifconfig enp0s1 | grep 'inet ' | awk '{print $2}')
CLUSTER_CONFIG_STAGING_DIR=/etc/k8s-config
mkdir -p $CLUSTER_CONFIG_STAGING_DIR
CLUSTER_CONFIG=${CLUSTER_CONFIG_STAGING_DIR}/cluster-config.yaml
jo apiVersion=kubeadm.k8s.io/v1beta3 kind=InitConfiguration nodeRegistration=$(jo name="master" criSocket="unix:///var/run/crio/crio.sock") | yq -rRy > $CLUSTER_CONFIG
echo "---" >> $CLUSTER_CONFIG
jo apiVersion=kubeadm.k8s.io/v1beta3 kind=ClusterConfiguration networking=$(jo podSubnet="10.85.0.0/16") controlPlaneEndpoint=$IP_ADDRESS apiServer=$(jo certSANs=$(jo -a "127.0.0.1" "$IP_ADDRESS" $(hostname))) | yq -rRy > $CLUSTER_CONFIG

# /usr/bin/kubeadm init --apiserver-advertise-address="${IP_ADDRESS}" --apiserver-cert-extra-sans="controlplane" --pod-network-cidr="172.17.0.0/16" --service-cidr="172.20.0.0/16"

/usr/bin/kubeadm init --config  $CLUSTER_CONFIG

