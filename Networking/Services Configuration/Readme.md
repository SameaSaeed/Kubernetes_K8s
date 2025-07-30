## **Service Configuration**



kubectl apply -f nginx-deployment.yaml



###### **1. Test internal connectivity via clusterIP service**



kubectl apply -f nginx-clusterip-service.yaml



\# Get clusterIP

kubectl get service nginx-clusterip-service -o wide



\#Run a test pod

kubectl run test-pod --image=busybox --rm -it --restart=Never -- sh



\# Test using the service IP (replace with your actual ClusterIP)

wget -qO- http://10.96.xxx.xxx



\# Test using service name (DNS resolution)

wget -qO- http://nginx-clusterip-service



\# Test using FQDN 

wget -qO- http://nginx-clusterip-service.default.svc.cluster.local



\# Exit the test pod

exit



###### **2. Test external connectivity via NodePortIP service**



\#Check default nodeport range

kubectl cluster-info dump | grep service-node-port-range



\#Create service

kubectl apply -f nginx-nodeport-auto.yaml

kubectl get service nginx-nodeport-auto

&nbsp;               or

kubectl apply -f nginx-nodeport-service.yaml



\#Get your node's external IP address

kubectl get nodes -o wide



\# Test from within the cluster

curl http://localhost:30080



\# If you have external access to the node

curl http://NODE\_EXTERNAL\_IP:30080



\# List all nodes

kubectl get nodes



\# Check if the service is accessible on each node

for node in $(kubectl get nodes -o jsonpath='{.items\[\*].status.addresses\[?(@.type=="InternalIP")].address}'); do

&nbsp; echo "Testing node: $node"

&nbsp; curl -s http://$node:30080 | grep -o "<title>.\*</title>" || echo "Failed to connect"

done



###### **3. LoadBalancer Service**



**A. Cloud**

\# Create service

kubectl apply -f nginx-loadbalancer-service.yaml



\#Wait for the external IP to be assigned

kubectl get service nginx-loadbalancer-service



\# Replace EXTERNAL-IP with the actual external IP

curl http://EXTERNAL-IP



\# Test load balancing by making multiple requests:

for i in {1..10}; do

&nbsp; curl -s http://EXTERNAL-IP | grep -o "Server: .\*" || echo "Request $i failed"

&nbsp; sleep 1

done



**B. Local**



\#Install MetalLB:

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml



\#Wait for MetalLB to be ready:

kubectl wait --namespace metallb-system \\

&nbsp; --for=condition=ready pod \\

&nbsp; --selector=app=metallb \\

&nbsp; --timeout=90s



\#Apply MetalLB

kubectl apply -f metallb-config.yaml



\#Check if your LoadBalancer service now has an external IP:

kubectl get service nginx-loadbalancer-service



###### **4. Service Discovery \& DNS Testing**



\# Create a test pod for DNS testing:

kubectl run dns-test --image=busybox --rm -it --restart=Never -- sh



\# From within the test pod, test different DNS resolution methods:



*# Test short name resolution*

*nslookup nginx-clusterip-service*



*# Test FQDN resolution*

*nslookup nginx-clusterip-service.default.svc.cluster.local*



*# Test service discovery*

*nslookup nginx-nodeport-service*



*# Exit the test pod*

*exit*



\# Check the endpoints created by your services:

kubectl get endpoints

kubectl describe endpoints nginx-clusterip-service



\#Check CoreDNS pods: 

kubectl get pods -n kube-system -l k8s-app=kube-dns



\#Test with FQDN: 

service-name.namespace.svc.cluster.local



###### **5. Service Troubleshooting \& Performance Monitoring:**



\#Fix the service

kubectl patch service nginx-broken-service -p '{"spec":{"selector":{"app":"nginx"}}}'



\#Monitor service connections:



\# Create a load testing pod

kubectl run load-test --image=busybox --rm -it --restart=Never -- sh



\# From within the load test pod, generate some traffic

for i in $(seq 1 100); do

&nbsp; wget -qO- http://nginx-clusterip-service > /dev/null

&nbsp; echo "Request $i completed"

done



exit

