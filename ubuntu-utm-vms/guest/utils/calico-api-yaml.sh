cat <<EOF
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kubernetes-services-endpoint
  namespace: tigera-operator
data:
  KUBERNETES_SERVICE_HOST: "$(kubectl get endpoints -n default kubernetes -o json | jq -r '.subsets[0].addresses[0].ip')"
  KUBERNETES_SERVICE_PORT: "$(kubectl get endpoints -n default kubernetes -o json | jq -r '.subsets[0].ports[0].port')"
EOF