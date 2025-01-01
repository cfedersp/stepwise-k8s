#!/bin/bash
mkdir -p /etc/cni/net.d
cp /usr/share/host/guest/cni/$1-11-crio-ipv4-bridge.conflist /etc/cni/net.d/11-crio-ipv4-bridge.conflist
