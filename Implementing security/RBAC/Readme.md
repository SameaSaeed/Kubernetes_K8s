\# \*\*Implement RBAC\*\*



##### A. RBAC



\### 1\\. Create a Dedicated Namespace







kubectl create namespace security-lab



kubectl config set-context --current --namespace=security-lab







\### 2\\. Create Service Accounts







kubectl create serviceaccount developer-sa -n security-lab



kubectl create serviceaccount viewer-sa -n security-lab



kubectl create serviceaccount admin-sa -n security-lab



kubectl get serviceaccounts -n security-lab







\### 3\\. Create Custom Roles







kubectl apply -f developer-role.yaml



kubectl apply -f viewer-role.yaml



kubectl get roles -n security-lab







\### 4\\. Create Role Bindings







kubectl apply -f developer-rolebinding.yaml



kubectl apply -f viewer-rolebinding.yaml



kubectl apply -f admin-clusterrolebinding.yaml



kubectl get rolebindings -n security-lab



kubectl get clusterrolebindings | grep admin-binding

(Create ClusterRole \& ClusterRoleBinding for Cross-Namespace Access)







\### 5\\. Create Pods with Specific Service Accounts \& Test Access Control





a. Create test resources



kubectl apply -f test-deployment.yaml





b. Get service account tokens





\\# Get the developer service account token



DEVELOPER\\\_TOKEN=$(kubectl create token developer-sa -n security-lab)



echo "Developer token: $DEVELOPER\\\_TOKEN"





\\# Get the viewer service account token



VIEWER\\\_TOKEN=$(kubectl create token viewer-sa -n security-lab)



echo "Viewer token: $VIEWER\\\_TOKEN"





\\# Get the admin service account token



ADMIN\\\_TOKEN=$(kubectl create token admin-sa -n security-lab)



echo "Admin token: $ADMIN\\\_TOKEN"





c. Test permissions



chmod +x scripts/audit-permissions.sh

./scripts/audit-permissions.sh



Use kubectl auth can-i to test specific permissions:



\# Test if dev team can create pods in development namespace

kubectl auth can-i create pods --as=system:serviceaccount:development:dev-team -n development



\# Test if prod-team can delete deployments in production namespace

kubectl auth can-i delete deployments --as=system:serviceaccount:production:prod-team -n production



\# Test if readonly-user can create secrets in testing namespace

kubectl auth can-i create secrets --as=system:serviceaccount:testing:readonly-user -n testing



\# Test cross-namespace access

kubectl auth can-i get pods --as=system:serviceaccount:development:dev-team -n production





\#### i. Test developer permissions (should succeed):







\\# Test listing pods as developer



kubectl --token=$DEVELOPER\\\_TOKEN get pods -n security-lab







\\# Test creating a configmap as developer



kubectl --token=$DEVELOPER\\\_TOKEN create configmap test-config --from-literal=key1=value1 -n security-lab







\\# Test scaling deployment as developer



kubectl --token=$DEVELOPER\\\_TOKEN scale deployment test-app --replicas=3 -n security-lab







\#### ii. Test viewer permissions (read operations should succeed):



\\# Test listing pods as viewer (should work)



kubectl --token=$VIEWER\\\_TOKEN get pods -n security-lab







\\# Test listing deployments as viewer (should work)



kubectl --token=$VIEWER\\\_TOKEN get deployments -n security-lab







Test viewer unauthorized actions (should fail):







\\# Test creating a configmap as viewer (should fail)



kubectl --token=$VIEWER\\\_TOKEN create configmap viewer-test --from-literal=key1=value1 -n security-lab







\\# Test deleting a pod as viewer (should fail)



kubectl --token=$VIEWER\\\_TOKEN delete pod $(kubectl get pods -n security-lab -o jsonpath='{.items\\\[0].metadata.name}') -n security-lab







\#### iii. Test admin permissions (should succeed for everything):







\\# Test cluster-wide operations as admin



kubectl --token=$ADMIN\\\_TOKEN get nodes







\\# Test creating resources in any namespace



kubectl --token=$ADMIN\\\_TOKEN create configmap admin-test --from-literal=admin=true -n default





##### B. Advanced RBAC Scenarios



1\. Resource-Specific Permissions

2\. Time-Based Access Control

3\. Network Policy Integration

##### 

##### C. Troubleshooting



Verify the pod is using the correct service account

Verify subject in ClusterRoleBinding matches service account

Check if service account token is mounted (api-communication)

Check if API server is accessible from pod

