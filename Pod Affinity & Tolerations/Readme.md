##### **Affinity, Anti-affinity, Taints, and Tolerations**



###### Add custom labels to nodes



\# Label the first worker node as a database tier

kubectl label nodes <worker-node-1> tier=database



\# Label the second worker node as a web tier

kubectl label nodes <worker-node-2> tier=web



\# Label a node with disk type

kubectl label nodes <worker-node-1> disk=ssd



\# Verify the labels were applied

kubectl get nodes --show-labels | grep tier



###### Deploy Pods with Node Affinity



**A. Create a database deployment that uses 'requiredDuringSchedulingIgnoredDuringExecution' node affinity.**

kubectl apply -f database-deployment.yaml



\# Check pod placement

kubectl get pods -o wide



\# Verify pods are scheduled on the correct node

kubectl describe pod <database-pod-name>



**B. Create a web deployment using 'preferredDuringSchedulingIgnoredDuringExecution' for more flexible scheduling.**

kubectl apply -f web-deployment.yaml



\# Observe pod distribution

kubectl get pods -o wide -l app=web



\# Check scheduling decisions

kubectl describe pods -l app=web



###### Apply taints to nodes \& tolerations to pods



**A.** Apply a taint to prevent general workloads



\#Taints prevent pods from being scheduled on nodes unless they have matching tolerations.

kubectl taint nodes <worker-node-1> dedicated=database:NoSchedule



\# Apply a taint that evicts existing pods

kubectl taint nodes <worker-node-2> maintenance=true:NoExecute



\# View node taints

kubectl describe node <worker-node-1> | grep -i taint

kubectl describe node <worker-node-2> | grep -i taint



B. Deploy Pods with Tolerations



\#Create a deployment that can tolerate the database taint. Apply the tolerant deployment

kubectl apply -f database-tolerant.yaml



\# Check where pods are scheduled

kubectl get pods -o wide -l app=database-tolerant



\# Verify toleration behavior

kubectl describe pods -l app=database-tolerant



C. Test Pod Scheduling Without Tolerations



\#Deploy a pod without tolerations to see the scheduling restriction.

kubectl apply -f no-toleration-pod.yaml



\# Check pod status (should be pending)

kubectl get pods no-toleration-test



\# Examine why it's not scheduled

kubectl describe pod no-toleration-test



###### Configuring Pod Affinity and Anti-Affinity



**A. Deploy Pods with Pod Affinity:** Create pods that prefer to be scheduled together using pod affinity.

kubectl apply -f frontend-with-affinity.yaml



\# Check pod placement relative to database pods

kubectl get pods -o wide



**B. Deploy Pods with Pod Anti-Affinity:** Create pods that should be spread across different nodes using anti-affinity.

kubectl apply -f cache-with-anti-affinity.yaml



\# Verify pods are distributed across nodes

kubectl get pods -o wide -l app=cache



\# Check if any pods are pending due to anti-affinity constraints

kubectl get pods -l app=cache



###### Advanced Scheduling Scenarios



**A. Combine Multiple Affinity Rules**

Create a complex deployment that combines node affinity, pod affinity, and tolerations.

kubectl apply -f complex-scheduling.yaml



\# Analyze the scheduling decisions

kubectl get pods -o wide -l app=complex

kubectl describe pods -l app=complex



###### Verification and Troubleshooting



**A. Comprehensive Scheduling Analysis**

\# Get overview of all pods and their node placement

kubectl get pods -o wide --all-namespaces



\# Check events for scheduling decisions

kubectl get events --sort-by=.metadata.creationTimestamp



\# Analyze specific pod scheduling

kubectl describe pod <pod-name> | grep -A 10 -B 5 "Events:"



\# Check node capacity and allocated resources

kubectl describe nodes | grep -A 5 "Allocated resources:"





**B. Test Scheduling Constraints**

Create test scenarios to verify our scheduling rules work correctly.



\# Scale up deployments to test constraints

kubectl scale deployment cache-app --replicas=5



\# Check if additional pods can be scheduled

kubectl get pods -l app=cache



\# Examine pending pods

kubectl describe pods -l app=cache | grep -A 10 "Events:"



\# Scale back down

kubectl scale deployment cache-app --replicas=2





**C. Remove Taints and Observe Changes**

Remove taints and observe how it affects pod scheduling.



\# Remove the NoExecute taint

kubectl taint nodes <worker-node-2> maintenance=true:NoExecute-



\# Remove the NoSchedule taint

kubectl taint nodes <worker-node-1> dedicated=database:NoSchedule-



\# Deploy a test pod to verify taint removal

kubectl run test-pod --image=nginx:1.21 --restart=Never



\# Check where the test pod is scheduled

kubectl get pod test-pod -o wide



\# Clean up test pod

kubectl delete pod test-pod



###### Monitoring and Validation



**A. Create Monitoring Script**

chmod +x monitor-scheduling.sh

./monitor-scheduling.sh



**B. Validate Affinity Rules**

\# Check database pods are on correct nodes

echo "Database pods placement:"

kubectl get pods -l app=database-tolerant -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,LABELS:.metadata.labels



\# Verify cache pods are distributed

echo -e "\\nCache pods distribution:"

kubectl get pods -l app=cache -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName



\# Check frontend pods affinity to database

echo -e "\\nFrontend and Database pod co-location:"

kubectl get pods -l 'app in (frontend,database-tolerant)' -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,APP:.metadata.labels.app



###### Troubleshooting



**Issue 1: Pods Stuck in Pending State**



\# Check pod events

kubectl describe pod <pending-pod-name>



\# Check node resources

kubectl describe nodes | grep -A 5 "Allocated resources"



\# Verify affinity/anti-affinity constraints

kubectl get pods -o yaml <pending-pod-name> | grep -A 20 affinity



Solutions: • Verify node labels match affinity requirements • Check if nodes have sufficient resources • Review anti-affinity rules that might be too restrictive • Ensure tolerations match node taints



**Issue 2: Pods Not Respecting Affinity Rules**



\# Check if affinity is preferred vs required

kubectl get pod <pod-name> -o yaml | grep -A 10 affinity



\# Verify node labels

kubectl get nodes --show-labels



Solutions: • Use requiredDuringSchedulingIgnoredDuringExecution for strict placement • Verify label selectors match exactly • Check topology key is appropriate for your cluster



**Issue 3: Taint/Toleration Mismatches**



\# Compare node taints with pod tolerations

kubectl describe node <node-name> | grep -i taint

kubectl get pod <pod-name> -o yaml | grep -A 5 tolerations



Solutions: • Ensure toleration key, value, and effect match exactly • Check toleration operator (Equal vs Exists) • Verify taint effect type (NoSchedule, PreferNoSchedule, NoExecute)



