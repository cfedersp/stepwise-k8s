#!/bin/bash

cat <<EOF
[req]
default_bits = 2048
prompt = no
encrypt_key = yes
default_md = sha256
distinguished_name = kubelet_serving
req_extensions = v3_req
[ kubelet_serving ]
O = system:nodes
CN = system:node:*.${CERT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = localhost
DNS.2 = *.${CERT_HEADLESS_SERVICE_NAME}
DNS.3 = *.${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}
DNS.4 = *.${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}.svc
DNS.5 = *.${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.6 = ${CERT_SERVICE_ROOT}
DNS.7 = ${CERT_SERVICE_ROOT}.${CERT_K8S_NAMESPACE}
DNS.8 = ${CERT_SERVICE_ROOT}.${CERT_K8S_NAMESPACE}.svc
DNS.9 = ${CERT_SERVICE_ROOT}.${CERT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.10 = ${CERT_NODEPORT_ROOT}.${CERT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.11 = *.${CERT_K8S_NAMESPACE}.pod.cluster.local
IP.1 = 127.0.0.1
EOF
