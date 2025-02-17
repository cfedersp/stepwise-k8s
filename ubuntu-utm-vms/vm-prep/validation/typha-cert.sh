TYPHA_SERVER=$(openssl x509 -noout -text -in /usr/share/host/guest/generated/certs/typha-tls.crt | grep -m 1 DNS | cut -d ':' -f2)
TYPHA_CLUSTERIP=$(kubectl get svc calico-typha -n calico-system -o json | jq -r '.spec.clusterIPs[0]' )
TYPHA_PORT=$(kubectl get svc calico-typha -n calico-system -o json | jq -r '.spec.ports[0].port' )
kubectl get cm tigera-ca-bundle -n calico-system -o json | jq -r '.data."tigera-ca-bundle.crt"' > guest/generated/certs/typha-root-ca.crt

curl https://$TYPHA_SERVER:$TYPHA_PORT -v --cacert /usr/share/host/guest/generated/certs/typha-root-ca.crt --resolve $TYPHA_SERVER:$TYPHA_PORT:$TYPHA_CLUSTERIP --cert /usr/share/host/guest/generated/certs/calico-node.crt --key /usr/share/host/guest/generated/certs/calico-node.key