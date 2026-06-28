#!/bin/bash
set -e -x
# $1 is the API server's DNS name, e.g. master.k8s-cluster.local
API_ENDPOINT_DOMAIN_NAME=$1
# Cluster DNS domain is derived by stripping the leftmost (host) label,
# e.g. master.k8s-cluster.local -> k8s-cluster.local
CLUSTER_DOMAIN_NAME=${API_ENDPOINT_DOMAIN_NAME#*.}
CLUSTER_CONFIG=$2
IP_ADDRESS=$(ip addr show enp0s1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
CLUSTER_CONFIG_STAGING_DIR=/etc/k8s-config
mkdir -p $CLUSTER_CONFIG_STAGING_DIR
jo apiVersion=kubeadm.k8s.io/v1beta3 kind=InitConfiguration nodeRegistration=$(jo name="master" criSocket="unix:///var/run/crio/crio.sock") | yq -rRy > $CLUSTER_CONFIG
echo "---" >> $CLUSTER_CONFIG
jo apiVersion=kubeadm.k8s.io/v1beta3 kind=ClusterConfiguration networking=$(jo podSubnet="10.85.0.0/16" dnsDomain="$CLUSTER_DOMAIN_NAME") controlPlaneEndpoint=$API_ENDPOINT_DOMAIN_NAME apiServer=$(jo certSANs=$(jo -a "127.0.0.1" "$IP_ADDRESS" $(hostname) $API_ENDPOINT_DOMAIN_NAME)) | yq -rRy >> $CLUSTER_CONFIG

# /usr/bin/kubeadm init --control-plane-endpoint= ${CLUSTER_DOMAIN_NAME} --apiserver-advertise-address="${IP_ADDRESS}" --apiserver-cert-extra-sans="controlplane" --pod-network-cidr="172.17.0.0/16" --service-cidr="172.20.0.0/16"
 

