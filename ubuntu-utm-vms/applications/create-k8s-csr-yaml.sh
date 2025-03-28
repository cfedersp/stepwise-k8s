#!/bin/bash

EXP_SECONDS=$((60*60*24*$2))

cat <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
   name: $1
spec:
   signerName: kubernetes.io/kubelet-serving
   expirationSeconds: $EXP_SECONDS
   request: $(cat $3 | base64 | tr -d '\n')
   usages:
   - digital signature
   - key encipherment
   - server auth
EOF
