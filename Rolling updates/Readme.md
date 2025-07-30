##### **Rolling updates**



1. ###### Deploy an app



\#Deploy an Application

kubectl apply -f nginx-deployment.yaml

kubectl apply -f nginx-service.yaml



\#Test the Initial Deployment

kubectl run test-pod --image=busybox --rm -it --restart=Never -- /bin/sh

wget -qO- nginx-service

exit



###### 2\. Perform a Rolling Update with Controlled Batch Sizes



Check the current deployment details:

kubectl describe deployment nginx-deployment



View the current replica set:

kubectl get replicasets -l app=nginx



Check the deployment rollout status:

kubectl rollout status deployment/nginx-deployment



Update the deployment to use a newer NGINX version:

kubectl set image deployment/nginx-deployment nginx=nginx:1.21



Watch the rolling update in real-time:

kubectl rollout status deployment/nginx-deployment --watch=true



In another terminal window, monitor the pods during the update:

watch kubectl get pods -l app=nginx



Observe the replica sets during the update:

kubectl get replicasets -l app=nginx



View the deployment history:

kubectl rollout history deployment/nginx-deployment



Get detailed information about a specific revision:

kubectl rollout history deployment/nginx-deployment --revision=2



###### 3\. Perform Another Rolling Update with Custom Strategy



Apply the updated deployment:

kubectl apply -f nginx-deployment-v2.yaml



Monitor the slower rolling update:

kubectl rollout status deployment/nginx-deployment --watch=true



Create a deployment with a problematic image:

kubectl set image deployment/nginx-deployment nginx=nginx:invalid-tag



Watch the failed update:

kubectl rollout status deployment/nginx-deployment --timeout=60s



Check the deployment status:

kubectl get deployments

kubectl get pods -l app=nginx



Check the rollout history:

kubectl rollout history deployment/nginx-deployment



Roll back to the previous version:

kubectl rollout undo deployment/nginx-deployment



Monitor the rollback process:

kubectl rollout status deployment/nginx-deployment



Verify the rollback was successful:

kubectl get pods -l app=nginx

kubectl describe deployment nginx-deployment



View the complete rollout history:

kubectl rollout history deployment/nginx-deployment



Roll back to a specific revision (e.g., revision 1):

kubectl rollout undo deployment/nginx-deployment --to-revision=1



Verify the rollback:

kubectl rollout status deployment/nginx-deployment

kubectl get pods -l app=nginx -o wide

###### 

###### 4\.  Analyze Deployment History and Revisions



a. 

chmod +x analyze-deployment.sh

./analyze-deployment.sh



b. 

Apply the configuration:

kubectl apply -f nginx-deployment-limited.yaml



Perform multiple updates to test revision limits:

kubectl set image deployment/nginx-deployment nginx=nginx:1.22

kubectl rollout status deployment/nginx-deployment



kubectl set image deployment/nginx-deployment nginx=nginx:1.23

kubectl rollout status deployment/nginx-deployment



kubectl set image deployment/nginx-deployment nginx=nginx:1.24

kubectl rollout status deployment/nginx-deployment



Check how many revisions are kept:

kubectl rollout history deployment/nginx-deployment

kubectl get replicasets -l app=nginx

###### 

###### 5\. Advanced Rolling Update Configurations



Apply the deployment with probes:

kubectl apply -f nginx-deployment-probes.yaml



Monitor the deployment with health checks:

kubectl rollout status deployment/nginx-deployment

kubectl get pods -l app=nginx



Test Rolling Update with Probes: Update the image and observe the behavior:

kubectl set image deployment/nginx-deployment nginx=nginx:1.22



Watch the pods transition:  

kubectl get pods -l app=nginx



Check pod readiness during the update:

kubectl describe pods -l app=nginx | grep -A 5 "Conditions"



###### 6\. Troubleshooting 



**Issue 1: Rolling Update Stuck: If a rolling update appears stuck:**



\# Check deployment status

kubectl describe deployment nginx-deployment



\# Check pod events

kubectl get events --sort-by=.metadata.creationTimestamp



\# Force restart if needed

kubectl rollout restart deployment/nginx-deployment



**Issue 2: Rollback Not Working: If rollback fails:**



\# Check rollout history

kubectl rollout history deployment/nginx-deployment



\# Manually scale down problematic replica set

kubectl scale replicaset <problematic-rs-name> --replicas=0



\# Force rollback

kubectl rollout undo deployment/nginx-deployment --force



**Issue 3: Resource Constraints: If pods fail to start due to resources:**



\# Check node resources

kubectl top nodes



\# Check pod resource requests

kubectl describe pods -l app=nginx | grep -A 5 "Requests"



\# Adjust resource limits in deployment

kubectl patch deployment nginx-deployment -p '{"spec":{"template":{"spec":{"containers":\[{"name":"nginx","resources":{"requests":{"memory":"32Mi","cpu":"100m"}}}]}}}}'

