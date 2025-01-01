#!/bin/bash
set -e -x
IP_ADDRESS=$(ifconfig enp0s1 | grep 'inet ' | awk '{print $2}')
CLUSTER_CONFIG_STAGING_DIR=/etc/k8s-config
sudo mkdir -p $CLUSTER_CONFIG_STAGING_DIR
CLUSTER_CONFIG=${CLUSTER_CONFIG_STAGING_DIR}/cluster-config.yaml
jo apiVersion=kubeadm.k8s.io/v1beta3 kind=InitConfiguration nodeRegistration=$(jo name="master" criSocket="unix:///var/run/crio/crio.sock") | yq -rRy > $CLUSTER_CONFIG
echo "---" >> $CLUSTER_CONFIG
jo apiVersion=kubeadm.k8s.io/v1beta3 kind=ClusterConfiguration networking=$(jo podSubnet="10.85.0.0/16") ncontrolPlaneEndpoint=$IP_ADDRESS apiServer=$(jo certSANs=$(jo -a "127.0.0.1" "$IP_ADDRESS")) | yq -rRy > $CLUSTER_CONFIG

/usr/bin/kubeadm init --config  $CLUSTER_CONFIG

