
#### **Service Mesh**

---

##### 1. Set up Istio:

```bash
# Download Istio installation script:
curl -L https://istio.io/downloadIstio | sh -

# Navigate to Istio directory and add istioctl to PATH:
cd istio-*
export PATH=$PWD/bin:$PATH

# Verify istioctl installation:
istioctl version

# Install Istio with default configuration profile:
istioctl install --set values.defaultRevision=default

# Verify Istio installation:
istioctl verify-install
kubectl get pods -n istio-system
# You should see pods like istiod, istio-proxy, and others running.

# Uninstall Istio
istioctl uninstall --purge
kubectl delete namespace istio-system

# Enable automatic sidecar injection for default namespace:
kubectl label namespace default istio-injection=enabled

# Verify namespace labeling:
kubectl get namespace -L istio-injection

# Pods not showing 2/2 ready status:
# Check if namespace has istio-injection label
# Restart pods after enabling injection:
kubectl rollout restart deployment/productpage-v1
```

---

##### 2. Deploy App

```bash
# Apply deployment
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

# Create Istio Gateway:
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

# Get the external IP of Istio ingress gateway:
kubectl get svc istio-ingressgateway -n istio-system
```

---

##### 3. Traffic Routing & Load Balancing

```bash
# Deploy different versions of the reviews service
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml

# Create destination rules with Load balancing for traffic management
kubectl apply -f destination-rule.yaml

# Apply the VirtualService:
kubectl apply -f reviews-virtual-service.yaml

# Get the gateway URL
export GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Test the application multiple times
for i in {1..10}; do
  curl -s "http://$GATEWAY_URL/productpage" | grep -o "glyphicon-star\|color:red"
done

# Cannot access application through gateway:
# - Verify gateway and virtual service configuration
# - Check if LoadBalancer service has external IP assigned

# Check proxy status
istioctl proxy-status

# Analyze configuration
istioctl analyze
```

---

##### 4. Implement Mutual TLS

```bash
# Check current mTLS status:
istioctl authn tls-check productpage.default.svc.cluster.local

# Create PeerAuthentication policy for strict mTLS
kubectl apply -f peer-authentication.yaml

# Check mTLS status after applying policy:
istioctl authn tls-check productpage.default.svc.cluster.local

# Verify mTLS is working by checking proxy configuration:
istioctl proxy-config cluster productpage-v1-<pod-id>.default --fqdn reviews.default.svc.cluster.local
# Replace <pod-id> with actual pod ID from:
kubectl get pods
```

###### **Test secure communication:**
```bash
# Deploy a test pod without Istio sidecar
kubectl create namespace test
kubectl run test-pod --image=curlimages/curl -n test --rm -it --restart=Never -- sh

# Try to access the service (should fail due to mTLS)
curl http://productpage.default.svc.cluster.local:9080/productpage

# mTLS not working?
# - Ensure PeerAuthentication policy is applied correctly
# - Check proxy configuration with istioctl commands
```

---

##### 5. Authorization

```bash
kubectl apply -f authorization-policy.yaml
```

---

##### 6. Monitor Service Mesh Traffic

###### **A. Install Kiali, Prometheus, Grafana, and Jaeger:**
```bash
kubectl apply -f samples/addons/kiali.yaml
kubectl apply -f samples/addons/prometheus.yaml
kubectl apply -f samples/addons/grafana.yaml
kubectl apply -f samples/addons/jaeger.yaml

# Wait for all observability pods to be ready:
kubectl get pods -n istio-system
```

###### **B. Generate continuous traffic:**
```bash
# Run this in a separate terminal
while true; do
  curl -s "http://$GATEWAY_URL/productpage" > /dev/null
  sleep 1
done
```

###### **C. Access Kiali Dashboard:**
```bash
kubectl port-forward -n istio-system svc/kiali 20001:20001
# Open browser: http://localhost:20001 (username: admin, password: admin)
```

###### **D. Access Grafana Dashboard:**
```bash
kubectl port-forward -n istio-system svc/grafana 3000:3000
# Open browser: http://localhost:3000
```

```bash
# Observability tools not accessible?
# - Verify all add-on pods are running
# - Check port-forward commands are correct

# Remove observability add-ons:
kubectl delete -f samples/addons/
```

---

##### 7. Analyze Service Mesh Metrics

###### **A. View service topology in Kiali:**
- Navigate to **Graph** section
- Select **default** namespace
- Observe service communication patterns

###### **B. Check Istio metrics in Grafana:**
- Go to **Dashboards → Istio**
- Explore **Istio Service Dashboard**
- Analyze **request rates, error rates, and latencies**

###### **C. Use istioctl for proxy analysis:**
```bash
# Check proxy configuration
istioctl proxy-config cluster productpage-v1-<pod-id>.default

# Check listeners
istioctl proxy-config listener productpage-v1-<pod-id>.default

# Check routes
istioctl proxy-config route productpage-v1-<pod-id>.default
```

---

##### 8. Advanced Traffic Management

###### **A. Fault Injection**
```bash
# Apply fault injection:
kubectl apply -f fault-injection.yaml

# Test fault injection with jason user (should experience delays and errors)
curl -H "end-user: jason" "http://$GATEWAY_URL/productpage"
```

###### **B. Timeout and Retry Policy**
```bash
kubectl apply -f timeout-retry.yaml
```
