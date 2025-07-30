##### **Ingress**



###### 1\. Deploy applications



\#Deploy two apps



\# Test internal connectivity

kubectl run test-pod --image=busybox --rm -it --restart=Never -- wget -qO- webapp1-service.ingress-lab.svc.cluster.local



###### 2\. Setup ingress controller



###### 3\. Create Ingress Deployments



a. Create IngressClass

b. Create Host-Based Routing

c. Create Path-Based Routing

d. Verify Ingress Configuration



\# List ingress resources

kubectl get ingress -n ingress-lab



\# Describe ingress for detailed information

kubectl describe ingress webapp-ingress -n ingress-lab

kubectl describe ingress webapp-path-ingress -n ingress-lab



\# Check ingress controller logs for any issues

kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=50



###### 4\. Test



**a. Host-based Routing**



\# Test app1.local

curl -H "Host: app1.local" http://$INGRESS\_IP/



\# Test app2.local

curl -H "Host: app2.local" http://$INGRESS\_IP/



\# Alternative testing using wget

wget -qO- --header="Host: app1.local" http://$INGRESS\_IP/



**b. Path-based Routing**



\# Test path-based routing for app1

curl -H "Host: myapp.local" http://$INGRESS\_IP/app1



\# Test path-based routing for app2

curl -H "Host: myapp.local" http://$INGRESS\_IP/app2



\# Test with verbose output to see headers

curl -v -H "Host: myapp.local" http://$INGRESS\_IP/app1



*Troubleshooting:*



\# Check ingress resource status

kubectl get ingress -A -o wide



\# Describe ingress for events and configuration

kubectl describe ingress -n ingress-lab



\# Check service endpoints

kubectl get endpoints -n ingress-lab



\# Verify pod connectivity

kubectl get pods -n ingress-lab -o wide



\# Test internal service resolution

kubectl run debug-pod --image=busybox --rm -it --restart=Never -- nslookup webapp1-service.ingress-lab.svc.cluster.local



\# Check ingress controller configuration

kubectl exec -n ingress-nginx deployment/ingress-nginx-controller -- cat /etc/nginx/nginx.conf | head -50



##### **API Gateway**



1. ###### Install API gateway



**a. Install Gateway API CRDs**



kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v0.8.1/standard-install.yaml



\# Verify CRDs installation

kubectl get crd | grep gateway



\# Check Gateway API resources

kubectl api-resources | grep gateway



**b. Install a Gateway API implementation (using NGINX Gateway Fabric):**



\# Create namespace for gateway

kubectl create namespace nginx-gateway



\# Install NGINX Gateway Fabric

kubectl apply -f https://github.com/nginxinc/nginx-gateway-fabric/releases/download/v1.0.0/nginx-gateway-fabric-1.0.0.yaml



\# Wait for gateway controller to be ready

kubectl wait --timeout=120s --for=condition=Available=true deployment/nginx-gateway -n nginx-gateway



###### 2\. Configure Gateway \& HTTP/HTTPS resources



a. Create Gateway Resource

b. Create HTTPRoute and HTTPSRoute Resources

c. Verify Gateway API Configuration



\# Check Gateway status

kubectl get gateway -n ingress-lab

kubectl describe gateway webapp-gateway -n ingress-lab



\# Check HTTPRoute status

kubectl get httproute -n ingress-lab

kubectl describe httproute webapp1-route -n ingress-lab

kubectl describe httproute webapp2-route -n ingress-lab



\# Check gateway controller logs

kubectl logs -n nginx-gateway deployment/nginx-gateway



###### 3\. Test HTTPS Access and Validation



\# Add secure hostname to /etc/hosts

sudo bash -c "echo '$INGRESS\_IP secure-app.local' >> /etc/hosts"

sudo bash -c "echo '$INGRESS\_IP gateway-app1.local' >> /etc/hosts"

sudo bash -c "echo '$INGRESS\_IP gateway-app2.local' >> /etc/hosts"



\# Verify /etc/hosts entries

grep "\\.local" /etc/hosts



\# Test HTTPS access (ignore certificate warnings for self-signed cert)

curl -k https://secure-app.local/



\# Test HTTP to HTTPS redirect

curl -v http://secure-app.local/



\# Test with certificate verification disabled and verbose output

curl -kv https://secure-app.local/



\# Check certificate details

openssl s\_client -connect secure-app.local:443 -servername secure-app.local < /dev/null



\# Get certificate information from the server

echo | openssl s\_client -servername secure-app.local -connect $INGRESS\_IP:443 2>/dev/null | openssl x509 -noout -text



\# Check certificate expiration

echo | openssl s\_client -servername secure-app.local -connect $INGRESS\_IP:443 2>/dev/null | openssl x509 -noout -dates



\# Verify certificate chain

curl -kv https://secure-app.local/ 2>\&1 | grep -E "(Server certificate|subject|issuer)"



##### **Advanced Traffic Management**



1. Configure Load Balancing
2. Implement Canary Deployment
3. Test Canary Deployment traffic distribution



\# Test multiple requests to see traffic distribution

echo "Testing traffic distribution (20% canary, 80% main):"

for i in {1..10}; do

&nbsp; echo "Request $i:"

&nbsp; curl -s -H "Host: app1.local" http://$INGRESS\_IP/ | grep -o "Web Application \[0-9]"

&nbsp; sleep 1

done



##### **Monitoring**



1. **Check ingress controller metrics and statu**s:



\# Check ingress controller metrics endpoint

kubectl port-forward -n ingress-nginx service/ingress-nginx-controller-metrics 10254:10254 \&

METRICS\_PID=$!



\# Wait a moment for port-forward to establish

sleep 3



\# Get metrics (run in background)

curl -s http://localhost:10254/metrics | grep nginx\_ingress



\# Stop port-forward

kill $METRICS\_PID



**2. Examine ingress access logs for troubleshooting:**



\# Get ingress controller logs with timestamps

kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=100 --timestamps



\# Follow logs in real-time (Ctrl+C to stop)

echo "Following ingress logs (press Ctrl+C to stop):"

kubectl logs -n ingress-nginx deployment/ingress-nginx-controller -f \&

LOGS\_PID=$!



\# Generate some traffic

curl -H "Host: app1.local" http://$INGRESS\_IP/

curl -H "Host: app2.local" http://$INGRESS\_IP/



\# Stop following logs

sleep 5

kill $LOGS\_PID

