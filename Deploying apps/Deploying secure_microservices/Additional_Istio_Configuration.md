
# Additional Istio Service Mesh Configuration Guide

---

## Subtask 2.1: Deploy Bookinfo Sample Application

```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl get services
kubectl get pods
kubectl wait --for=condition=ready pod --all --timeout=300s
```

## Subtask 2.2: Deploy Gateway and Virtual Service

```bash
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl get gateway
kubectl get virtualservice
```

## Subtask 2.3: Get Ingress Gateway URL

```bash
kubectl get svc istio-ingressgateway -n istio-system
export INGRESS_HOST=$(minikube ip)
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
curl -s http://${GATEWAY_URL}/productpage | grep -o "<title>.*</title>"
```

---

## Task 3: Configure Traffic Policies and Security

### Subtask 3.1: Create Destination Rules

```bash
# Apply destination rules using here-document
<destination-rule YAMLs already included, no need to repeat>
kubectl get destinationrules
```

### Subtask 3.2: Implement Authorization Policies

<authorization policies already included, no need to repeat>

### Subtask 3.3: Test Authorization Policies

```bash
curl -s http://${GATEWAY_URL}/productpage | grep -o "<title>.*</title>"
echo "Testing authorized access..."
curl -s -o /dev/null -w "%{http_code}" http://${GATEWAY_URL}/productpage
```

### Subtask 3.4: Verify Unauthorized Access

```bash
# Create test pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  labels:
    app: test
spec:
  containers:
  - name: test
    image: curlimages/curl:latest
    command: ["/bin/sh"]
    args: ["-c", "sleep 3600"]
EOF

kubectl wait --for=condition=ready pod test-pod --timeout=60s

# Test unauthorized access
kubectl exec test-pod -- curl -s -o /dev/null -w "%{http_code}" http://productpage:9080/productpage
kubectl exec test-pod -- curl -s -o /dev/null -w "%{http_code}" http://details:9080/details/1
```

---

## Task 4: Configure Observability and Monitoring

### Subtask 4.2: Generate Traffic for Monitoring

```bash
for i in {1..100}; do
  curl -s http://${GATEWAY_URL}/productpage > /dev/null
  echo "Request $i completed"
  sleep 1
done
```

### Subtask 4.3 & 4.4: Access Kiali and Grafana

```bash
istioctl dashboard kiali --browser=false &
echo "Kiali dashboard available at: http://localhost:20001"
kubectl port-forward -n istio-system svc/kiali 20001:20001 &

istioctl dashboard grafana --browser=false &
echo "Grafana dashboard available at: http://localhost:3000"
kubectl port-forward -n istio-system svc/grafana 3000:3000 &
```

---

## Task 5: Test mTLS Communication

### Subtask 5.2: Analyze Traffic Encryption

```bash
REVIEWS_POD=$(kubectl get pod -l app=reviews,version=v1 -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config cluster $REVIEWS_POD --fqdn ratings.default.svc.cluster.local
istioctl proxy-config secret $REVIEWS_POD -o json | jq '.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 -d | openssl x509 -text -noout | head -20
```

---

## Task 6: Advanced Security Configuration

### Subtask 6.1: Configure Request Authentication

```bash
# JWT authentication policy
<JWT policy YAML already included, skipped here>
```

### Subtask 6.2: Create Network Policies

<NetworkPolicy YAML already included, skipped here>

---

## Troubleshooting Tips

```bash
# Check sidecar injection
kubectl get namespace default --show-labels
kubectl label namespace default istio-injection=enabled --overwrite

# Check mTLS setup
kubectl get peerauthentication --all-namespaces
kubectl get destinationrules -o yaml

# Check authorization service accounts
kubectl get serviceaccounts
istioctl authn tls-check <service-name>

# Observability dashboard issues
kubectl get pods -n istio-system
kubectl port-forward -n istio-system svc/kiali 20001:20001
```

---

## Final Verification and Cleanup

```bash
# Final checks
istioctl authn tls-check productpage.default.svc.cluster.local
curl -s -o /dev/null -w "%{http_code}" http://${GATEWAY_URL}/productpage
kubectl logs -n istio-system deployment/istiod | grep -i "certificate"
istioctl proxy-config secret $PRODUCTPAGE_POD

# Cleanup
kubectl delete -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f samples/bookinfo/networking/bookinfo-gateway.yaml
kubectl delete authorizationpolicy --all
kubectl delete destinationrules --all
kubectl delete pod test-pod
kubectl delete -f samples/addons/
istioctl uninstall --purge -y
kubectl label namespace default istio-injection-
```

