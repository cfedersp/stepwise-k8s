cat <<EOF
kind: ConfigMap
apiVersion: v1
metadata:
  name: kubernetes-services-endpoint
  namespace: tigera-operator
data:
  KUBERNETES_SERVICE_HOST: "$(ifconfig enp0s1 | grep 'inet ' | awk '{print $2}')"
  KUBERNETES_SERVICE_PORT: "$(kubectl get endpoints -n default kubernetes -o json | jq -r '.subsets[0].ports[0].port')"
EOF