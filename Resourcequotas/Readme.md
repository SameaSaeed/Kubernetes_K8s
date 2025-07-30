##### Resource Quotas



1\. Deploy app



kubectl create namespace resource-lab

kubectl config set-context --current --namespace=resource-lab



\#Create a Pod manifest with resource specifications

kubectl apply -f pod-with-resources.yaml



\#Verify the Pod is running and check its resource allocation:

kubectl get pods -o wide

kubectl describe pod resource-demo-pod



\#Examine the resource section in the Pod description:

Look for the Requests and Limits sections in the output. Note how: • Requests: Guaranteed resources the Pod will receive • Limits: Maximum resources the Pod can consume



2\. Implementing Namespace-Level ResourceQuotas



Apply the ResourceQuota:

kubectl apply -f resource-quota.yaml



Verify the ResourceQuota is active:

kubectl get resourcequota -n resource-lab

kubectl describe resourcequota compute-quota -n resource-lab



Create a Pod that exceeds the quota

kubectl apply -f large-pod.yaml

Expected Result: You should see an error message indicating that the ResourceQuota would be exceeded.



Check the current quota usage:

kubectl describe resourcequota compute-quota -n resource-lab



3\. Deploy Applications with Resource Constraints



Create a Deployment with Resource Specifications

kubectl apply -f web-deployment.yaml



Monitor the deployment progress:

kubectl get deployments -n resource-lab

kubectl get pods -n resource-lab



Check if all replicas are created successfully:

kubectl describe deployment web-app -n resource-lab



Check current resource usage against quotas:

kubectl describe resourcequota compute-quota -n resource-lab

Calculate total resource consumption:

The output should show: • Used vs Hard limits for each resource type • Current consumption by all Pods in the namespace



Attempt to scale the deployment beyond quota limits:

kubectl scale deployment web-app --replicas=8 -n resource-lab



Check the scaling result:

kubectl get deployments -n resource-lab

kubectl describe deployment web-app -n resource-lab

Note: Some replicas may not be created if they would exceed the ResourceQuota.



4\. Advanced Resource Management



\#Create a LimitRange to set default resource values

kubectl apply -f limit-range.yaml



Verify the LimitRange is active:

kubectl get limitrange -n resource-lab

kubectl describe limitrange default-limits -n resource-lab



\#Create a Pod without explicit resource specifications:

kubectl apply -f pod-no-resources.yaml



\#Check if default resources were applied:

kubectl describe pod default-resources-pod -n resource-lab

Expected Result: The Pod should have the default resource requests and limits applied automatically.



5\. Monitoring



Check overall namespace resource consumption:

kubectl top pods -n resource-lab



View detailed resource information for all Pods:

kubectl get pods -n resource-lab -o custom-columns=NAME:.metadata.name,CPU-REQUEST:.spec.containers\[0].resources.requests.cpu,MEMORY-REQUEST:.spec.containers\[0].resources.requests.memory,CPU-LIMIT:.spec.containers\[0].resources.limits.cpu,MEMORY-LIMIT:.spec.containers\[0].resources.limits.memory



Monitor quota usage over time:

watch -n 5 'kubectl describe resourcequota compute-quota -n resource-lab'

Press Ctrl+C to stop the watch command.



6\. Troubleshooting



Attempt to create the Pod:

kubectl apply -f problematic-pod.yaml



Investigate the failure:

kubectl get events -n resource-lab --sort-by='.lastTimestamp'

kubectl describe resourcequota compute-quota -n resource-lab



Fix the issue by adjusting resources:

kubectl apply -f fixed-pod.yaml

kubectl get pods -n resource-lab



Issue 1: Pod Creation Fails Due to ResourceQuota

Symptoms: Error message about exceeding ResourceQuota Solution: • Check current quota usage with kubectl describe resourcequota • Reduce resource requests/limits in Pod specification • Scale down existing deployments to free up quota



Issue 2: Pods Stuck in Pending State

Symptoms: Pods remain in Pending status Solution: • Check node resources with kubectl describe nodes • Verify resource requests don't exceed node capacity • Review events with kubectl get events



Issue 3: Metrics Server Not Available

Symptoms: kubectl top commands fail Solution: • This is normal in some lab environments • Use kubectl describe commands to view resource specifications • Focus on quota and limit configurations rather than real-time metrics

