## **Implement Admission Controllers**



1. ##### Explore Current Admission Controllers



Check the current admission controllers configuration:

kubectl get pods -n kube-system kube-apiserver-\* -o yaml | grep admission-plugins



Get detailed information about the API server configuration:

kubectl describe pod -n kube-system $(kubectl get pods -n kube-system | grep kube-apiserver | awk '{print $1}') | grep admission



List all available admission controllers:

kubectl api-versions | grep admission



Check if Pod Security Admission is enabled:

kubectl get --raw /api/v1 | grep -i security



Examine the current Pod Security Standards:

kubectl explain pod.spec.securityContext



##### 2\. Enable and Configure Pod Security Admission



a. Create namespaces 

kubectl create namespace restricted-test

kubectl create namespace baseline-test

kubectl create namespace privileged-test



Verify the namespaces were created:

kubectl get namespaces | grep test



b. Configure Pod Security Standards



Apply restricted security standard to the restricted-test namespace:

kubectl label namespace restricted-test \\

&nbsp; pod-security.kubernetes.io/enforce=restricted \\

&nbsp; pod-security.kubernetes.io/audit=restricted \\

&nbsp; pod-security.kubernetes.io/warn=restricted



Apply baseline security standard to the baseline-test namespace:

kubectl label namespace baseline-test \\

&nbsp; pod-security.kubernetes.io/enforce=baseline \\

&nbsp; pod-security.kubernetes.io/audit=baseline \\

&nbsp; pod-security.kubernetes.io/warn=baseline



Apply privileged security standard to the privileged-test namespace:

kubectl label namespace privileged-test \\

&nbsp; pod-security.kubernetes.io/enforce=privileged \\

&nbsp; pod-security.kubernetes.io/audit=privileged \\

&nbsp; pod-security.kubernetes.io/warn=privileged



Verify the labels were applied correctly:

kubectl get namespaces --show-labels | grep test



c. Create Pod Security Policy Test Files

privileged-pod.yaml

baseline-pod.yaml

restricted-pod.yaml



##### 3\. Test Admission Controller Policies



a. Test Privileged Pod Restrictions



Try to deploy the privileged pod in the restricted namespace (should fail):

kubectl apply -f privileged-pod.yaml -n restricted-test



Try to deploy the privileged pod in the baseline namespace (should fail):

kubectl apply -f privileged-pod.yaml -n baseline-test



Deploy the privileged pod in the privileged namespace (should succeed):

kubectl apply -f privileged-pod.yaml -n privileged-test



Verify the pod status:

kubectl get pods -n privileged-test

kubectl describe pod privileged-pod -n privileged-test



b. Test Baseline Pod Compliance



Try to deploy the baseline pod in the restricted namespace (should fail):

kubectl apply -f baseline-pod.yaml -n restricted-test



Deploy the baseline pod in the baseline namespace (should succeed):

kubectl apply -f baseline-pod.yaml -n baseline-test



Deploy the baseline pod in the privileged namespace (should succeed):

kubectl apply -f baseline-pod.yaml -n privileged-test



Check the pod status in both namespaces:

kubectl get pods -n baseline-test

kubectl get pods -n privileged-test



c. Test Restricted Pod Compliance



Deploy the restricted pod in the restricted namespace (should succeed):

kubectl apply -f restricted-pod.yaml -n restricted-test



Deploy the restricted pod in the baseline namespace (should succeed):

kubectl apply -f restricted-pod.yaml -n baseline-test



Deploy the restricted pod in the privileged namespace (should succeed):

kubectl apply -f restricted-pod.yaml -n privileged-test



Verify all deployments:

kubectl get pods -n restricted-test

kubectl get pods -n baseline-test

kubectl get pods -n privileged-test

##### 

##### 4\. Verify Enforcement Using Sample Deployments



privileged-deployment.yaml

baseline-deployment.yaml

restricted-deployment.yaml



a. Test privileged deployment in different namespaces:

\# Should fail in restricted namespace

kubectl apply -f privileged-deployment.yaml -n restricted-test



\# Should fail in baseline namespace

kubectl apply -f privileged-deployment.yaml -n baseline-test



\# Should succeed in privileged namespace

kubectl apply -f privileged-deployment.yaml -n privileged-test



b. Test baseline deployment in different namespaces:

\# Should fail in restricted namespace

kubectl apply -f baseline-deployment.yaml -n restricted-test



\# Should succeed in baseline namespace

kubectl apply -f baseline-deployment.yaml -n baseline-test



c. Test restricted deployment in all namespaces:

\# Should succeed in all namespaces

kubectl apply -f restricted-deployment.yaml -n restricted-test

kubectl apply -f restricted-deployment.yaml -n baseline-test



d. Monitor deployment status:

kubectl get deployments -A | grep -E "(restricted|baseline|privileged)"

kubectl get pods -A | grep -E "(restricted|baseline|privileged)"



##### 5\. Analyze Policy Violations



Check events for policy violations:

kubectl get events -n restricted-test --sort-by='.lastTimestamp'

kubectl get events -n baseline-test --sort-by='.lastTimestamp'



Examine detailed error messages:

kubectl describe deployment privileged-deployment -n restricted-test

kubectl describe deployment baseline-deployment -n restricted-test



View admission controller logs:

kubectl logs -n kube-system $(kubectl get pods -n kube-system | grep kube-apiserver | awk '{print $1}') | grep -i admission



##### 6\. Advanced Configuration and Testing



a. Configure Namespace-Level Policies



Create a namespace with mixed enforcement levels:

kubectl create namespace mixed-policy-test



Apply different policy levels for different actions:

kubectl label namespace mixed-policy-test \\

&nbsp; pod-security.kubernetes.io/enforce=baseline \\

&nbsp; pod-security.kubernetes.io/audit=restricted \\

&nbsp; pod-security.kubernetes.io/warn=restricted



Test the mixed policy configuration:

kubectl apply -f baseline-pod.yaml -n mixed-policy-test

kubectl get events -n mixed-policy-test



b. Create Custom Security Contexts



kubectl apply -f custom-security-pod.yaml -n baseline-test

kubectl apply -f custom-security-pod.yaml -n restricted-test



##### 

##### 7\. Resource Quota (Add-on)



a. kubectl describe pod kube-apiserver-$(hostname) -n kube-system | grep admission

kubectl apply -f resource-quota.yaml



b. Test Resource Quota Enforcement

kubectl apply -f resource-heavy-deployment.yaml

kubectl get deployment resource-heavy-app -n security-lab

kubectl describe resourcequota security-lab-quota -n security-lab



#### 8\. Configure Network policies (Add-on)



a.

kubectl apply -f network-policy.yaml

kubectl get networkpolicies -n security-lab

kubectl describe networkpolicy deny-all-ingress -n security-lab



b. Verify Network Policy Enforcement



###### **I. Test network connectivity for the allowed client pod**



kubectl apply -f test-client.yaml



\# Wait for pod to be ready

kubectl wait --for=condition=Ready pod/test-client -n security-lab --timeout=60s



\# Get the IP of one of the test-app pods

TEST\_APP\_IP=$(kubectl get pod -l app=test-app -n security-lab -o jsonpath='{.items\[0].status.podIP}')



\# Test connection from allowed client (should work)

kubectl exec test-client -n security-lab -- wget -qO- --timeout=5 http://$TEST\_APP\_IP



###### **II. Test for unauthorized client pod**



kubectl apply -f unauthorized-client.yaml



\# Wait for pod to be ready

kubectl wait --for=condition=Ready pod/unauthorized-client -n security-lab --timeout=60s



\# Test connection from unauthorized client (should fail/timeout)

kubectl exec unauthorized-client -n security-lab -- timeout 10 wget -qO- http://$TEST\_APP\_IP || echo "Connection blocked by network policy"

##### 

##### 9\. Troubleshooting 



Issue 1: Pod Security Admission not working

Verify Kubernetes version (PSA requires 1.23+)

Check if admission controller is enabled in API server configuration

Ensure proper namespace labeling syntax



Issue 2: Pods failing to start in restricted namespace

Verify all security context requirements are met

Check that runAsNonRoot is set to true

Ensure capabilities are properly dropped

Verify seccomp profile is set



Issue 3: Deployment creation succeeds but pods fail

Check ReplicaSet events for detailed error messages

Verify pod template security context matches namespace requirements

Review admission controller logs for specific violations



Issue 4: Mixed policy levels not working as expected

Understand the difference between enforce, audit, and warn modes

Check events and logs for audit and warning messages

Verify label syntax and values



##### 10\. Debugging Commands



\# Check admission controller configuration

kubectl get pods -n kube-system kube-apiserver-\* -o yaml | grep -A 10 -B 10 admission



\# View detailed pod security violations

kubectl get events --field-selector type=Warning



\# Check namespace labels

kubectl get namespaces --show-labels



\# Describe failed pods for detailed error information

kubectl describe pod <pod-name> -n <namespace>

