##### A. Pod Security Policies:



###### 1\. Baseline policy

kubectl create namespace security-demo



\#Apply Baseline policy to the security-demo namespace

kubectl label namespace security-demo \\

&nbsp; pod-security.kubernetes.io/enforce=baseline \\

&nbsp; pod-security.kubernetes.io/audit=baseline \\

&nbsp; pod-security.kubernetes.io/warn=baseline



\#Try to apply pods

kubectl apply -f baseline-allowed-pod.yaml

kubectl apply -f baseline-rejected-pod.yaml (it should be rejected)



###### 2\. Restricted policy

\#Create a dedicated namespace

kubectl create namespace restricted-demo



\#Apply restricted policy to the namespace:

kubectl label namespace restricted-demo \\

&nbsp; pod-security.kubernetes.io/enforce=restricted \\

&nbsp; pod-security.kubernetes.io/audit=restricted \\

&nbsp; pod-security.kubernetes.io/warn=restricted



\#Apply the restricted-compliant pod

kubectl apply -f restricted-compliant-pod.yaml



\#Pod Security Admission not working

kubectl get --raw /api/v1 | grep PodSecurity



##### B. Network Policies



1. Document Initial Connectivity Results, as mentioned in the multi-tier app lab
2. Create a Default Deny Network Policy: kubectl apply -f database-default-deny.yaml
3. Create Specific Allow Policies: 

kubectl apply -f allow-backend-to-database.yaml

kubectl apply -f allow-database-dns.yaml (database pods to make dns queries: egress)

kubectl apply -f allow-frontend-to-backend.yaml

4\. Create egress policy: kubectl apply -f backend-egress-policy.yaml

5\. Test:

kubectl apply -f test-pod.yaml



\#Verify your CNI supports Network Policies:

kubectl get pods -n kube-system | grep -E "(calico|cilium|weave)"



kubectl exec test-connectivity -- timeout 5 sh -c "nc -zv database-service.database.svc.cluster.local 3306" || echo "Connection blocked as expected"

6\. Check for any policy violations in system logs:

kubectl logs -n kube-system -l k8s-app=calico-node --tail=50 | grep -i "denied\\|blocked" || echo "No blocked connections found in recent logs"

