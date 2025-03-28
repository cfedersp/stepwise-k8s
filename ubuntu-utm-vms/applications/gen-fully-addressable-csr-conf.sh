#!/bin/bash

cat <<EOF
[ req ]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = v3_ext
distinguished_name = dn

[ dn ]
C = US
ST = California
L = San Diego
O = Geek.dev
OU = Ledgerbadger
CN = $1

[ v3_ext ]
basicConstraints = CA:FALSE
keyUsage = keyEncipherment,dataEncipherment
extendedKeyUsage = $2
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
DNS.2 = ${CERT_HEADLESS_SERVICE_NAME}
DNS.3 = *.${CERT_HEADLESS_SERVICE_NAME}
DNS.4 = ${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}
DNS.5 = *.${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}
DNS.6 = ${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}.svc
DNS.7 = *.${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}.svc
DNS.8 = ${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.9 = *.${CERT_HEADLESS_SERVICE_NAME}.${CERT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.10 = ${CERT_SERVICE_ROOT}
DNS.11 = ${CERT_SERVICE_ROOT}.${CERT_K8S_NAMESPACE}
DNS.12 = ${CERT_SERVICE_ROOT}.${CERT_K8S_NAMESPACE}.svc
DNS.13 = ${CERT_SERVICE_ROOT}.${CERT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.14 = ${CERT_NODEPORT_ROOT}.${CERT_K8S_NAMESPACE}.svc.${K8S_CLUSTER_NAME}
DNS.15 = *.${CERT_K8S_NAMESPACE}.pod.cluster.local
IP.1 = 127.0.0.1
EOF
