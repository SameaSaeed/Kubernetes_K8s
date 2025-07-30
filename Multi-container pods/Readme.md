a.

Deploy the pod to your Kubernetes cluster:

kubectl apply -f multi-container-pod.yaml



Verify the pod is running:

kubectl get pods



Check the status of all containers in the pod:

kubectl get pod multi-container-app -o jsonpath='{.status.containerStatuses\[\*].name}'

echo

kubectl get pod multi-container-app -o jsonpath='{.status.initContainerStatuses\[\*].name}'



b. 

View the init container logs to verify it completed successfully:

kubectl logs multi-container-app -c config-setup

You should see output similar to:

Initializing configuration...

Configuration setup complete!



c.

Check that the configuration files were created properly:

kubectl exec multi-container-app -c web-app -- ls -la /etc/app-config/

kubectl exec multi-container-app -c web-app -- cat /etc/app-config/app.conf



d.

First, get the pod's IP address:

kubectl get pod multi-container-app -o wide



Create a test pod to generate HTTP requests:

kubectl run test-client --image=busybox:1.35 --rm -it --restart=Never -- /bin/sh



Inside the test client pod, generate some HTTP requests:

\# Replace POD\_IP with the actual IP from the previous command

wget -q -O- http://POD\_IP

wget -q -O- http://POD\_IP/nonexistent

wget -q -O- http://POD\_IP

exit



e. 

View the sidecar container logs to see it processing the access logs:

kubectl logs multi-container-app -c log-sidecar --tail=20



f.

Check that both containers can access the shared volume:



\# Check from the main container

kubectl exec multi-container-app -c web-app -- ls -la /var/log/nginx/



\# Check from the sidecar container

kubectl exec multi-container-app -c log-sidecar -- ls -la /var/log/nginx/

##### 

##### Advanced Multi-Container Scenarios



Create an advanced multi-container pod with multiple sidecar containers

kubectl apply -f advanced-multi-container.yaml



Check the status of all containers:



kubectl get pod advanced-multi-container

kubectl describe pod advanced-multi-container

View logs from different containers:



\# Main application logs

kubectl logs advanced-multi-container -c main-app --tail=10



\# Monitor sidecar logs

kubectl logs advanced-multi-container -c monitor-sidecar --tail=10



\# Cleanup sidecar logs

kubectl logs advanced-multi-container -c cleanup-sidecar --tail=10

##### 

##### Troubleshooting



a. 

\# Get detailed pod information

kubectl describe pod multi-container-app



\# Check events related to the pod

kubectl get events --field-selector involvedObject.name=multi-container-app



\# Check resource usage

kubectl top pod multi-container-app --containers



\# Execute commands in specific containers

kubectl exec multi-container-app -c web-app -- ps aux

kubectl exec multi-container-app -c log-sidecar -- ps aux



b.

\# Write a file from the main container

kubectl exec multi-container-app -c web-app -- sh -c 'echo "Hello from web-app" > /var/log/nginx/test-message.txt'



\# Read the file from the sidecar container

kubectl exec multi-container-app -c log-sidecar -- cat /var/log/nginx/test-message.txt



c.

\# Check memory and CPU usage

kubectl top pod multi-container-app --containers



\# Get detailed resource information

kubectl describe pod multi-container-app | grep -A 10 "Containers:"



##### Troubleshooting 



Issue: Init container fails to complete Solution: Check init container logs with kubectl logs pod-name -c init-container-name



Issue: Containers cannot access shared volumes Solution: Verify volume mounts in the pod specification and ensure paths are correct



Issue: Sidecar container not seeing main container logs Solution: Ensure both containers mount the same volume path and the main container is writing to the expected location



Issue: Pod stuck in Pending state. Solution: Check node resources with kubectl describe nodes and pod events with kubectl describe pod pod-name



##### Debugging



\# View all container logs

kubectl logs pod-name --all-containers=true



\# Follow logs in real-time

kubectl logs -f pod-name -c container-name



\# Get shell access to specific container

kubectl exec -it pod-name -c container-name -- /bin/sh



\# Check volume mounts

kubectl describe pod pod-name | grep -A 5 "Mounts:"

