#!/bin/bash

cat <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
   name: $1
spec:
   signerName: kubernetes.io/kubelet-serving
   expirationSeconds: 8640000
   request: $(cat $2 | base64 | tr -d '\n')
   usages:
   - digital signature
   - key encipherment
   - server auth
EOF
