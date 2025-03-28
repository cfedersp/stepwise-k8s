#!/bin/bash
set -e -x

KUBECONFIG=/usr/share/host/guest/generated/users/calico-cni.kubeconfig
if  [ ! -f ${KUBECONFIG} ] ; then
    echo "Kubeconfig for Calico is missing! $KUBECONFIG"
    exit 1;
fi
cp ${KUBECONFIG} /etc/cni/net.d/calico-kubeconfig
chmod 600 /etc/cni/net.d/calico-kubeconfig

if ! [ -f /opt/cni/bin/calico ]; then
    cp /usr/share/host/guest/all-nodes/downloads/calico /opt/cni/bin/
fi
if ! [ -f /opt/cni/bin/calico-ipam ]; then
    cp /usr/share/host/guest/all-nodes/downloads/calico-ipam /opt/cni/bin/
fi

chmod 755 /opt/cni/bin/calico*

confFiles=(/etc/cni/net.d/*.conflist)
if [ ${#confFiles[@]} ]; then
    # for file in /etc/cni/net.d/*.conflist; do mv "$file" "${file/conflist/conflist.disabled}"; done
    for file in "${confFiles[@]}"; do mv "$file" "${file/conflist/conflist.disabled}"; done
fi
cp /usr/share/host/guest/cni/10-calico.conflist /etc/cni/net.d/

kubectl create clusterrolebinding calico-cni --clusterrole=calico-cni --user=calico-cni