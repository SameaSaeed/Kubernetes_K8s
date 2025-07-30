#### **CNI and Network Policies**



##### 1\. Current Network State



Examine current network configuration:

\# Check if any CNI plugin is currently installed

ls -la /etc/cni/net.d/



\# Check current Pod network status

kubectl get pods --all-namespaces -o wide

Verify kubelet configuration for CNI:

\# Check kubelet configuration

sudo systemctl status kubelet



\# Look for CNI-related parameters

sudo cat /var/lib/kubelet/config.yaml | grep -i network



##### 2\. Apply resources



\# Create a test namespace

kubectl create namespace network-test



\# Deploy test pods on different nodes

kubectl apply -f test-pods.yaml



\# Wait for pods to be running

kubectl wait --for=condition=Ready pod/test-pod-1 -n network-test --timeout=60s

kubectl wait --for=condition=Ready pod/test-pod-2 -n network-test --timeout=60s



\# Get pod IPs

kubectl get pods -n network-test -o wide



##### 3\. Configure Calico



###### A. Setup



\# Create directory for CNI configurations

mkdir -p ~/cni-configs

cd ~/cni-configs



\# Download Calico manifest

curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml



\# Examine the custom resources file

cat custom-resources.yaml



\# Create a customized version for our lab

kubectl apply -f calico-custom-resources.yaml



\# Apply the Tigera operator

kubectl create -f tigera-operator.yaml



\# Wait for operator to be ready

kubectl wait --for=condition=Ready pod -l k8s-app=tigera-operator -n tigera-operator --timeout=120s



\# Install Calico with custom configuration

kubectl create -f calico-custom-resources.yaml



\# Monitor Calico installation progress

kubectl get pods -n calico-system --watch



\# Check all Calico pods are running

kubectl get pods -n calico-system



\# Verify Calico node status

kubectl get nodes -o wide



\# Check CNI configuration files

ls -la /etc/cni/net.d/

cat /etc/cni/net.d/10-calico.conflist

###### 

###### B. Verify Calico Functionality



Test Pod-to-Pod connectivity with Calico:

\# Delete existing test pods to get new IPs with Calico

kubectl delete pods --all -n network-test



\# Recreate test pods

kubectl apply -f calico-test-pods.yaml



Test connectivity between pods:

\# Wait for pods to be ready

kubectl wait --for=condition=Ready pod/calico-test-pod-1 -n network-test --timeout=60s

kubectl wait --for=condition=Ready pod/calico-test-pod-2 -n network-test --timeout=60s



\# Get pod IPs

POD1\_IP=$(kubectl get pod calico-test-pod-1 -n network-test -o jsonpath='{.status.podIP}')

POD2\_IP=$(kubectl get pod calico-test-pod-2 -n network-test -o jsonpath='{.status.podIP}')



echo "Pod 1 IP: $POD1\_IP"

echo "Pod 2 IP: $POD2\_IP"



\# Test connectivity from pod 1 to pod 2

kubectl exec -n network-test calico-test-pod-1 -- ping -c 3 $POD2\_IP



\# Test connectivity from pod 2 to pod 1

kubectl exec -n network-test calico-test-pod-2 -- ping -c 3 $POD1\_IP



##### 4\. Configure Flannel CNI



###### A. Setup



Create a new namespace for Flannel testing:



\# Simulate Flannel installation by creating a test environment

\# In production, you would typically choose one CNI plugin per cluster

kubectl create namespace flannel-test



\# Download Flannel manifest

curl -O https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml



\# Examine Flannel configuration

cat kube-flannel.yml | head -50

##### 

##### 5\. Analyze Flannel vs Calico Configuration



\# Create comparison script

chmod +x compare-cni.sh

./compare-cni.sh

##### 

##### 6\. Verify Pod Connectivity Across Nodes



**Test pod-pod connectivity across nodes**



\#Deploy Multi-Node Test Application

kubectl apply -f connectivity-test-app.yaml



\# Wait for deployment to be ready

kubectl wait --for=condition=Available deployment/connectivity-test -n network-test --timeout=120s



\# Check pod distribution across nodes

kubectl get pods -n network-test -o wide --selector=app=connectivity-test



\# Get all test pod names and IPs

kubectl get pods -n network-test -l app=connectivity-test -o custom-columns=NAME:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName



\# Create connectivity test script

chmod +x test-connectivity.sh

./test-connectivity.sh



**Test Service Connectivity**



\# Test service discovery and connectivity

SERVICE\_IP=$(kubectl get service connectivity-test-service -n network-test -o jsonpath='{.spec.clusterIP}')

echo "Service IP: $SERVICE\_IP"



\# Test service connectivity from each pod

PODS=$(kubectl get pods -n network-test -l app=connectivity-test -o jsonpath='{.items\[\*].metadata.name}')



for pod in $PODS; do

&nbsp;   echo "Testing service connectivity from $pod:"

&nbsp;   kubectl exec -n network-test $pod -- nslookup connectivity-test-service.network-test.svc.cluster.local

&nbsp;   echo ""

done



**3. Test Cross-Namespace Connectivity**



kubectl apply -f cross-namespace-pod.yaml



\# Get pod IP from cross-test namespace

CROSS\_POD\_IP=$(kubectl get pod cross-namespace-pod -n cross-test -o jsonpath='{.status.podIP}')

echo "Cross-namespace pod IP: $CROSS\_POD\_IP"



\# Test connectivity from network-test namespace to cross-test namespace

FIRST\_POD=$(kubectl get pods -n network-test -l app=connectivity-test -o jsonpath='{.items\[0].metadata.name}')



echo "Testing cross-namespace connectivity:"

kubectl exec -n network-test $FIRST\_POD -- ping -c 3 $CROSS\_POD\_IP



##### 7\. Network Failures Troubleshooting



**Configure monitoring tools:**

chmod +x monitor-network.sh

./monitor-network.sh



**Simulate CNI pod failure:**

\# Get one of the Calico node pods

CALICO\_POD=$(kubectl get pods -n calico-system -l k8s-app=calico-node -o jsonpath='{.items\[0].metadata.name}')

echo "Simulating failure of Calico pod: $CALICO\_POD"



\# Delete the Calico pod to simulate failure

kubectl delete pod $CALICO\_POD -n calico-system



\# Monitor recovery

echo "Monitoring Calico pod recovery..."

kubectl get pods -n calico-system -l k8s-app=calico-node --watch \&

WATCH\_PID=$!



\# Wait for 30 seconds then stop watching

sleep 30

kill $WATCH\_PID 2>/dev/null



**Examine CNI and kubelet logs:**

\# Check Calico node logs

echo "=== Calico Node Logs ==="

CALICO\_POD=$(kubectl get pods -n calico-system -l k8s-app=calico-node -o jsonpath='{.items\[0].metadata.name}')

kubectl logs $CALICO\_POD -n calico-system -c calico-node --tail=50



echo ""

echo "=== Kubelet Logs ==="

sudo journalctl -u kubelet --no-pager --lines=20



echo ""

echo "=== CNI Configuration ==="

cat /etc/cni/net.d/10-calico.conflist | jq '.'



**Create continuous connectivity test**

chmod +x continuous-test.sh

./continuous-test.sh



**Create comprehensive troubleshooting script**

chmod +x troubleshoot-network.sh

./troubleshoot-network.sh > network-troubleshoot-report.txt



echo "Troubleshooting report saved to: network-troubleshoot-report.txt"

cat network-troubleshoot-report.txt



**Implement network recovery script**

chmod +x recover-network.sh

./recover-network.sh



##### 8\. Advanced CNI Configuration and Network Policies



a. Create namespaces and deployments for frontend, backend and database \& Test initial connectivity as in a multi-tier app deployment (should work without network policies)



b. Create restrictive network policies, Add labels to namespaces for network policy selectors

kubectl label namespace frontend name=frontend

kubectl label namespace backend name=backend

kubectl label namespace database name=database



c. Test network policy enforcement

chmod +x test-network-policies.sh

./test-network-policies.sh



##### 9\. Performance Analysis and Optimization



Install network performance testing tools iperf3

Run script



