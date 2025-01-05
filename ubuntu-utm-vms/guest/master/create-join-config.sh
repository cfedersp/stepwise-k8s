#!/bin/bash

getValidTokens(){
	echo $(kubeadm token list | grep -v invalid | grep -v TOKEN | head -1 | cut -d ' ' -f1)
}
DISCOVERY_TOKEN=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

EXISTING_TOKENS=$(kubeadm token list)
JOINTOKEN=$(getValidTokens)
if test -z $JOINTOKEN ; then
  EXISTING_TOKENS=$(kubeadm token create)
  echo "Created new: $EXISTING_TOKENS"
  JOINTOKEN=$(getValidTokens)
fi

echo $JOINTOKEN

APISERVER_ENDPOINT=$(kubectl get pod kube-apiserver-master -n kube-system -o json | jq -r '.metadata.annotations["kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint"]')

# Hash is provided so fingerprint can be verified, therefore we dont need unsafeSkipCAVerification
# jo apiVersion=kubeadm.k8s.io/v1beta3 kind=JoinConfiguration nodeRegistration=$(jo name="master" criSocket="unix:///var/run/crio/crio.sock") discovery=$(jo bootstrapToken=$(jo apiServerEndpoint=$APISERVER_ENDPOINT token=$JOINTOKEN caCertHashes=$(jo -a "sha256:$DISCOVERY_TOKEN"))) unsafeSkipCAVerification=true > $1/master-join-config.json

jo apiVersion=kubeadm.k8s.io/v1beta3 kind=JoinConfiguration nodeRegistration=$(jo name="master" criSocket="unix:///var/run/crio/crio.sock") discovery=$(jo bootstrapToken=$(jo apiServerEndpoint=$APISERVER_ENDPOINT token=$JOINTOKEN caCertHashes=$(jo -a "sha256:$DISCOVERY_TOKEN"))) > $1/master-join-config.json
