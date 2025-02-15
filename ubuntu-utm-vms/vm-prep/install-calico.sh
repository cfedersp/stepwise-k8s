#!/bin/bash

cp /usr/share/host/guest/all-nodes/downloads/calico /opt/cni/bin/
cp /usr/share/host/guest/all-nodes/downloads/calico-ipam /opt/cni/bin/

chmod 755 /opt/cni/bin/calico*

if test -f /etc/cni/net.d/*.conflist; then
    for file in /etc/cni/net.d/*.conflist; do mv "$file" "${file/conflist/conflist.disabled}"; done
fi
cp /usr/share/host/guest/cni/10-calico.conflist /etc/cni/net.d/
