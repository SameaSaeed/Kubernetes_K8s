##### Analyzing Kubernetes Component Logs



###### 1\. Examining kube-apiserver Logs



Step 1: Identify how kube-apiserver is running in your cluster

kubectl get pods -n kube-system | grep apiserver



Step 2: If kube-apiserver runs as a static pod, view its logs using kubectl

kubectl logs -n kube-system kube-apiserver-$(hostname) --tail=50



Step 3: If kube-apiserver runs as a system service, use journalctl

sudo journalctl -u kube-apiserver --no-pager --lines=50



Step 4: Filter logs for specific error patterns

kubectl logs -n kube-system kube-apiserver-$(hostname) | grep -i error



Step 5: Monitor real-time logs to observe API server activity

kubectl logs -n kube-system kube-apiserver-$(hostname) -f

Press Ctrl+C to stop the real-time monitoring.



###### 2\. Examining kubelet Logs



Step 1: Check kubelet service status

sudo systemctl status kubelet



Step 2: View recent kubelet logs using journalctl

sudo journalctl -u kubelet --no-pager --lines=50



Step 3: Filter kubelet logs for Pod-related issues

sudo journalctl -u kubelet | grep -i "failed\\|error\\|warning"



Step 4: Monitor kubelet logs in real-time

sudo journalctl -u kubelet -f



Step 5: Check kubelet logs for a specific time period

sudo journalctl -u kubelet --since "10 minutes ago"



###### 3\. Creating a Log Analysis Script

chmod +x collect\_k8s\_logs.sh

./collect\_k8s\_logs.sh

##### 

#####  Debugging a Failing Pod



###### 1.Logging



kubectl apply -f failing-pod.yaml

kubectl get pod failing-app -o yaml | grep -A 20 "status:"

kubectl logs failing-app

kubectl get events --sort-by=.metadata.creationTimestamp (Stuck pending)



kubectl exec working-app -- cat /var/log/nginx/access.log

###### 

##### Troubleshooting Network Connectivity



1. ###### Testing Basic Network Connectivity with Ping



Step 1: Get the IP addresses of the test Pods

kubectl get pods -l app=network-test -o wide



Step 2: Store the server Pod IP for testing

SERVER\_POD\_IP=$(kubectl get pod server-pod -o jsonpath='{.status.podIP}')

echo "Server Pod IP: $SERVER\_POD\_IP"



Step 3: Test ping connectivity from client to server Pod

kubectl exec client-pod -- ping -c 4 $SERVER\_POD\_IP



Step 4: Test ping to the service IP

SERVICE\_IP=$(kubectl get service server-service -o jsonpath='{.spec.clusterIP}')

echo "Service IP: $SERVICE\_IP"

kubectl exec client-pod -- ping -c 4 $SERVICE\_IP



Step 5: Test ping to external addresses

kubectl exec client-pod -- ping -c 4 8.8.8.8

kubectl exec client-pod -- ping -c 4 google.com

###### 

###### 2\. Testing HTTP Connectivity



Step 1: Test HTTP connectivity to the server Pod directly

kubectl exec client-pod -- wget -qO- http://$SERVER\_POD\_IP



Step 2: Test HTTP connectivity via the service

kubectl exec client-pod -- wget -qO- http://server-service



Step 3: Test with curl for more detailed output

kubectl exec client-pod -- wget -O- --timeout=10 http://server-service 2>\&1



###### 3\. Using Traceroute for Network Path Analysis



Step 1: Install traceroute in the client Pod

kubectl exec client-pod -- sh -c 'which traceroute || echo "traceroute not available in busybox"'



Step 2: Use alternative network diagnostic tools available in busybox

kubectl exec client-pod -- netstat -rn

kubectl exec client-pod -- route -n



Step 3: Test network connectivity with telnet-like functionality

kubectl exec client-pod -- nc -zv $SERVER\_POD\_IP 80

kubectl exec client-pod -- nc -zv server-service 80



###### 4\. Advanced Network Troubleshooting



kubectl apply -f debug-pod.yaml

kubectl wait --for=condition=Ready pod/debug-pod --timeout=60s



a. Use advanced networking tools from the debug Pod

kubectl exec debug-pod -- nslookup server-service

kubectl exec debug-pod -- dig server-service

kubectl exec debug-pod -- traceroute $SERVER\_POD\_IP



b. Analyze network interfaces and routing

kubectl exec debug-pod -- ip addr show

kubectl exec debug-pod -- ip route show

kubectl exec debug-pod -- ss -tuln



###### 5\. Troubleshooting DNS Resolution



a.

Step 1: Test DNS resolution within the cluster

kubectl exec debug-pod -- nslookup kubernetes.default.svc.cluster.local

kubectl exec debug-pod -- nslookup server-service.default.svc.cluster.local



Step 2: Check DNS configuration

kubectl exec debug-pod -- cat /etc/resolv.conf



Step 3: Test external DNS resolution

kubectl exec debug-pod -- nslookup google.com

kubectl exec debug-pod -- dig @8.8.8.8 google.com



b. 

\# Apply file

kubectl apply -f dns-debug.yaml



\# Test DNS resolution again

kubectl wait --for=condition=ready pod -n network-debug dns-debug --timeout=60s

kubectl exec -n network-debug dns-debug -- nslookup kubernetes.default.svc.cluster.local



###### 6\. Network Troubleshooting Script/Analyzing Networking Issues with tcpdump and traceroute



a. Create applications with networking issues

kubectl apply -f  web-app-problem.yaml



\# Wait for pods to be ready

kubectl wait --for=condition=ready pod -l app=web-app -n network-debug --timeout=60s

kubectl wait --for=condition=ready pod -l app=client-app -n network-debug --timeout=60s



\# Get pod and service information

kubectl get pods -n network-debug -o wide

kubectl get svc -n network-debug



b. Test connectivity from client pod

CLIENT\_POD=$(kubectl get pods -n network-debug -l app=client-app -o jsonpath='{.items\[0].metadata.name}')

kubectl exec -n network-debug $CLIENT\_POD -- curl -m 5 web-service.network-debug.svc.cluster.local

\# This should fail or timeout



c. Capture network traffic with tcpdump to diagnose issues

\# Get worker node where web-app pod is running

WEB\_POD=$(kubectl get pods -n network-debug -l app=web-app -o jsonpath='{.items\[0].metadata.name}')

NODE\_NAME=$(kubectl get pod -n network-debug $WEB\_POD -o jsonpath='{.spec.nodeName}')



\# Get pod IP

POD\_IP=$(kubectl get pod -n network-debug $WEB\_POD -o jsonpath='{.status.podIP}')



\# Start tcpdump on the node (run this in background)

sudo tcpdump -i any host $POD\_IP -w /tmp/pod-traffic.pcap \&

TCPDUMP\_PID=$!



\# Generate traffic from client

kubectl exec -n network-debug $CLIENT\_POD -- curl -m 5 web-service.network-debug.svc.cluster.local



\# Stop tcpdump

sleep 5

sudo kill $TCPDUMP\_PID



\# Analyze captured traffic

sudo tcpdump -r /tmp/pod-traffic.pcap -n



d. Use traceroute for Path Analysis

\# Install traceroute in client pod

kubectl exec -n network-debug $CLIENT\_POD -- sh -c "apk add --no-cache traceroute"



\# Trace route to service

SERVICE\_IP=$(kubectl get svc -n network-debug web-service -o jsonpath='{.spec.clusterIP}')

kubectl exec -n network-debug $CLIENT\_POD -- traceroute $SERVICE\_IP



\# Trace route to pod directly

kubectl exec -n network-debug $CLIENT\_POD -- traceroute $POD\_IP



e. Analyze and Fix Network Issues

\# Check service endpoints

kubectl get endpoints -n network-debug web-service



\# The issue is port mismatch - service targets port 8080 but container listens on 80

\# Fix the service configuration

kubectl patch svc -n network-debug web-service -p '{"spec":{"ports":\[{"port":80,"targetPort":80}]}}'



\# Verify fix

kubectl get endpoints -n network-debug web-service



\# Test connectivity again

kubectl exec -n network-debug $CLIENT\_POD -- curl -m 5 web-service.network-debug.svc.cluster.local



f. chmod +x network\_troubleshoot.sh

./network\_troubleshoot.sh





###### 7\. Debug Misconfigured kube-apiserver



a. Simulate a common misconfiguration



\# Backup original configuration

sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.backup



\# Introduce error - invalid port configuration

sudo sed -i 's/--secure-port=6443/--secure-port=invalid-port/' /etc/kubernetes/manifests/kube-apiserver.yaml



\# Wait for kubelet to detect change and restart apiserver

sleep 30



\# Verify apiserver is failing

kubectl get nodes

\# This should fail with connection errors



b. Diagnose the Issue



\# Check apiserver pod status

sudo crictl ps -a | grep apiserver



\# Check apiserver logs

sudo crictl logs $(sudo crictl ps -a | grep apiserver | head -1 | awk '{print $1}')



\# Check kubelet logs for apiserver restart attempts

sudo journalctl -u kubelet -f --since "5 minutes ago" | grep apiserver



c. Fix the configuration error



\# Restore original configuration

sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml.backup /etc/kubernetes/manifests/kube-apiserver.yaml



\# Wait for apiserver to restart

sleep 60



\# Verify apiserver is running

kubectl get nodes



\# Check apiserver pod status

kubectl get pods -n kube-system | grep apiserver



d. Advanced Configuration Debugging



\# Introduce certificate path error

sudo sed -i 's|--tls-cert-file=/etc/kubernetes/pki/apiserver.crt|--tls-cert-file=/etc/kubernetes/pki/wrong-cert.crt|' /etc/kubernetes/manifests/kube-apiserver.yaml



\# Wait and observe failure

sleep 30



\# Check logs for certificate errors

sudo crictl logs $(sudo crictl ps -a | grep apiserver | head -1 | awk '{print $1}') 2>\&1 | grep -i cert



\# Fix the issue

sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml.backup /etc/kubernetes/manifests/kube-apiserver.yaml



\# Verify recovery

sleep 60

kubectl get nodes



###### 8\. Troubleshooting



Common kube-apiserver Issues:

• Port conflicts: Ensure secure-port is not already in use • Certificate problems: Verify all certificate paths and validity • Resource limits: Check if apiserver has sufficient memory and CPU • Configuration syntax: Validate YAML syntax in manifest files

###### 

###### 9\. Verification 



\# Verify etcd health

sudo ETCDCTL\_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \\

&nbsp; --cacert=/etc/kubernetes/pki/etcd/ca.crt \\

&nbsp; --cert=/etc/kubernetes/pki/etcd/server.crt \\

&nbsp; --key=/etc/kubernetes/pki/etcd/server.key \\

&nbsp; endpoint health



\# Verify apiserver is running

kubectl get componentstatuses



\# Verify network connectivity

kubectl exec -n network-debug $CLIENT\_POD -- curl -s web-service.network-debug.svc.cluster.local | grep "Welcome to nginx"



Common Network Issues:

• Service selector mismatch: Ensure service selectors match pod labels • Port configuration: Verify targetPort matches container port • DNS resolution: Check if CoreDNS is running and configured correctly • Network policies: Ensure network policies allow required traffic

