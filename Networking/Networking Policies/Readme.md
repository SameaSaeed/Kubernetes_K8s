##### 1\. Setting up



\# Check cluster connection

kubectl cluster-info



\# Verify nodes are ready

kubectl get nodes



\# Check if Network Policy support is available

kubectl get pods -n kube-system | grep -E "(calico|cilium|weave)"



##### 2\. Create resources



\#Create development and production namespaces \& apply their manifests.



\# Apply the pods

kubectl apply -f dev-web-pod.yaml

kubectl apply -f dev-db-pod.yaml

kubectl apply -f prod-web-pod.yaml

kubectl apply -f prod-db-pod.yaml



\# Check pod labels

kubectl get pods -n development --show-labels

kubectl get pods -n production --show-labels



\# Apply the test client pod

kubectl apply -f test-client-pod.yaml



##### 3\. Test Cross-Namespace Communication



\# Get IP addresses of target pods

DEV\_WEB\_IP=$(kubectl get pod web-app -n development -o jsonpath='{.status.podIP}')

PROD\_WEB\_IP=$(kubectl get pod web-app -n production -o jsonpath='{.status.podIP}')

DEV\_DB\_IP=$(kubectl get pod database -n development -o jsonpath='{.status.podIP}')

PROD\_DB\_IP=$(kubectl get pod database -n production -o jsonpath='{.status.podIP}')



echo "Development Web IP: $DEV\_WEB\_IP"

echo "Production Web IP: $PROD\_WEB\_IP"

echo "Development DB IP: $DEV\_DB\_IP"

echo "Production DB IP: $PROD\_DB\_IP"



##### 4\. Perform Connectivity Tests with test-pod



\# Test connectivity to development web pod

kubectl exec -it test-client -n development -- wget -qO- --timeout=5 http://$DEV\_WEB\_IP



\# Test connectivity to production web pod (cross-namespace)

kubectl exec -it test-client -n development -- wget -qO- --timeout=5 http://$PROD\_WEB\_IP



\# Test connectivity to development database

kubectl exec -it test-client -n development -- nc -zv $DEV\_DB\_IP 3306



\# Test connectivity to production database (cross-namespace)

kubectl exec -it test-client -n development -- nc -zv $PROD\_DB\_IP 3306



##### 5\. Implement Network Policies for Isolation



1. ###### Create default-deny policy for development and production and test



\# Test connectivity to development web pod (should fail)

kubectl exec -it test-client -n development -- timeout 10 wget -qO- http://$DEV\_WEB\_IP || echo "Connection blocked as expected"



\# Test connectivity to production web pod (should fail)

kubectl exec -it test-client -n development -- timeout 10 wget -qO- http://$PROD\_WEB\_IP || echo "Connection blocked as expected"



###### 2\. Configure Selective Allow Policies



**a. Create policies**



A. Allow Intra-Namespace Communication in Development

B. Allow Web Tier to Database Communication

C. Allow Client Access to Web Applications

D. Allow Specific Cross-Namespace Communication



\# Add required labels to namespaces

kubectl label namespace development name=development environment=dev --overwrite

kubectl label namespace production name=production environment=prod --overwrite



\# Verify labels

kubectl get namespaces --show-labels



**b. Test and Validate Network Policies**



\# Test client to development web (should work)

kubectl exec -it test-client -n development -- wget -qO- --timeout=10 http://$DEV\_WEB\_IP



\# Test development web to development database (should work)

kubectl exec -it web-app -n development -- nc -zv $DEV\_DB\_IP 3306



\# Test development web to production database (should work due to cross-namespace policy)

kubectl exec -it web-app -n development -- nc -zv $PROD\_DB\_IP 3306



\# Test client to production web (should fail - no policy allows this)

kubectl exec -it test-client -n development -- timeout 10 wget -qO- http://$PROD\_WEB\_IP || echo "Blocked as expected"



\# Test client to development database (should fail - no direct client-to-db policy)

kubectl exec -it test-client -n development -- timeout 10 nc -zv $DEV\_DB\_IP 3306 || echo "Blocked as expected"



\# Apply the production test client

kubectl apply -f prod-test-client.yaml



\# Wait for pod to be ready

kubectl wait --for=condition=Ready pod/test-client -n production --timeout=60s



\# Test production client to production web (should fail - no policy allows this)

kubectl exec -it test-client -n production -- timeout 10 wget -qO- http://$PROD\_WEB\_IP || echo "Blocked as expected"



\# Test production client to development resources (should fail)

kubectl exec -it test-client -n production -- timeout 10 wget -qO- http://$DEV\_WEB\_IP || echo "Blocked as expected"

##### 

##### 6\. Advanced Policies



1. Implement Egress policy
2. Create Time-Based Access Simulation

# Add additional labels to pods for advanced selection
kubectl label pod web-app -n development access-level=standard
kubectl label pod database -n development access-level=restricted
kubectl label pod test-client -n development access-level=testing

# Create advanced policy using multiple label selectors
kubectl apply -f dev-advanced-policy.yaml



##### 7\. Monitoring



\# List all network policies

kubectl get networkpolicies --all-namespaces



\# Get detailed information about a specific policy

kubectl describe networkpolicy default-deny-ingress -n development



\# View policy in YAML format

kubectl get networkpolicy allow-web-to-db -n development -o yaml



\# Check policy labels and selectors

kubectl get networkpolicy -n development --show-labels



\# Check pod labels to ensure they match policy selectors

kubectl get pods -n development --show-labels

kubectl get pods -n production --show-labels



\# Verify namespace labels

kubectl get namespaces --show-labels



\# Test DNS resolution

kubectl exec -it test-client -n development -- nslookup web-app.development.svc.cluster.local



\# Check if policies are being applied correctly

kubectl get networkpolicy -n development -o wide



\# Make script executable and run it

chmod +x test-network-policies.sh

./test-network-policies.sh



##### 8\. Export Policy Configurations



\# Create backup directory

mkdir -p network-policy-backup



\# Export all network policies

kubectl get networkpolicy -n development -o yaml > network-policy-backup/development-policies.yaml

kubectl get networkpolicy -n production -o yaml > network-policy-backup/production-policies.yaml



\# Export pod configurations

kubectl get pods -n development -o yaml > network-policy-backup/development-pods.yaml

kubectl get pods -n production -o yaml > network-policy-backup/production-pods.yaml



\# Export namespace configurations

kubectl get namespace development -o yaml > network-policy-backup/development-namespace.yaml

kubectl get namespace production -o yaml > network-policy-backup/production-namespace.yaml



echo "All configurations backed up to network-policy-backup/ directory"



##### 9\. Troubleshooting



1. Policies not taking place



\# Check if your cluster supports Network Policies

kubectl get pods -n kube-system | grep -E "(calico|cilium|weave)"



\# Verify policy syntax

kubectl describe networkpolicy <policy-name> -n <namespace>



\# Check for conflicting policies

kubectl get networkpolicy --all-namespaces



2\. Pods communication



\# Verify pod labels match policy selectors

kubectl get pods --show-labels -n <namespace>



\# Check namespace labels

kubectl get namespaces --show-labels



\# Ensure DNS resolution works

kubectl exec -it <pod-name> -n <namespace> -- nslookup kubernetes.default



3\. Cross-Namespace Policies Not Working



\# Verify namespace selectors in policies

kubectl get networkpolicy <policy-name> -n <namespace> -o yaml



\# Check namespace labels

kubectl describe namespace <namespace-name>



\# Test with IP addresses instead of DNS names

kubectl get pods -o wide --all-namespaces



4\. DNS resolution Problem



\# Add DNS egress rules to policies

\# Example egress rule for DNS:

\# - to: \[]

\#   ports:

\#   - protocol: TCP

\#     port: 53

\#   - protocol: UDP

\#     port: 53



\# Test DNS resolution

kubectl exec -it <pod-name> -n <namespace> -- nslookup google.com

