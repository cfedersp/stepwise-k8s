#!/bin/bash
set -e -x 

rm /etc/cni/net.d/10-calico.conflist || true
mv /etc/cni/net.d/11-crio-ipv4-bridge.conflist.disabled /etc/cni/net.d/11-crio-ipv4-bridge.conflist
rm /etc/cni/net.d/calico-kubeconfig || true
echo "AFTER REBOOT, REMEMBER TO RUN "sudo ./cni-routes.sh", THEN UNSEAL VAULT PODS!'
shutdown -r