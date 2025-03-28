#!/bin/bash

cat <<EOF
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: allow-ledgerbadger-vault
spec:
  preDNAT: true
  applyOnForward: true
  order: 10
  ingress:
    - action: Allow
      source:
        nets: [192.168.1.0/24]
      protocol: TCP
      destination:
        selector: has(kubernetes-host)
        ports: [32395]
  selector: has(kubernetes-host)
EOF