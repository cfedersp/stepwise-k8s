#!/bin/bash

cat <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
   name: $1
spec:
   signerName: kubernetes.io/kube-apiserver-client
   request: $(cat $2 | base64 | tr -d '\n')
   usages:
   - client auth
EOF
