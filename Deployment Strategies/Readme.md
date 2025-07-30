### Deployment Strategies



#### **Blue-Green Deployment**



a. App deployment



Apply the deployment:

kubectl apply -f app-deployment-v1.yaml



Apply the service:

kubectl apply -f app-service.yaml



Get the cluster IP and test the application:

\# If using minikube

minikube ip



\# Test the application (replace <MINIKUBE\_IP> with actual IP)

curl http://<MINIKUBE\_IP>:30080



\# Alternative: Port forward for testing

kubectl port-forward service/sample-app-service 8080:80 \&

curl http://localhost:8080



b.  Implement Blue/Green Deployment Strategy



&nbsp;a. Create the green environment deployment:

kubectl apply -f app-deployment-v2.yaml



Verify both environments are running:

kubectl get deployments

kubectl get pods -l app=sample-app --show-labels



##### Test Both Environments Separately



kubectl apply -f blue-green-services.yaml



**Test both versions:**

\# Test Blue version (v1)

curl http://<MINIKUBE\_IP>:30081



\# Test Green version (v2)

curl http://<MINIKUBE\_IP>:30082



\# Or use port forwarding

kubectl port-forward service/sample-app-blue 8081:80 \&

kubectl port-forward service/sample-app-green 8082:80 \&



curl http://localhost:8081

curl http://localhost:8082



**Switch Traffic from Blue to Green**



Update the main service to point to the green environment:

kubectl patch service sample-app-service -p '{"spec":{"selector":{"app":"sample-app","version":"v2"}}}'



Verify the traffic switch:

kubectl describe service sample-app-service

curl http://<MINIKUBE\_IP>:30080



Monitor the switch and verify no downtime occurred:

\# Check service endpoints

kubectl get endpoints sample-app-service



\# Verify pods are healthy

kubectl get pods -l app=sample-app,version=v2



**Implement Rollback Capability**



chmod +x rollback-to-blue.sh



Test the rollback:

./rollback-to-blue.sh

curl http://<MINIKUBE\_IP>:30080



Switch back to green for the next task:

kubectl patch service sample-app-service -p '{"spec":{"selector":{"app":"sample-app","version":"v2"}}}'



#### **Canary Deployment**



a.

Reset the main service to serve all traffic to v1 (Blue):

kubectl patch service sample-app-service -p '{"spec":{"selector":{"app":"sample-app","version":"v1"}}}'



Scale down v2 deployment temporarily:

kubectl scale deployment sample-app-v2 --replicas=0



Create a new version (v3) for canary testing

kubectl apply -f app-deployment-v3.yaml



Configure the service for canary deployment by removing version selector:

kubectl patch service sample-app-service -p '{"spec":{"selector":{"app":"sample-app"}}}'



b.

Calculate pod ratios for 10% traffic split:

Stable version (v1): 9 replicas (90%)

Canary version (v3): 1 replica (10%)



Scale the deployments accordingly:

\# Scale stable version to 9 replicas

kubectl scale deployment sample-app-v1 --replicas=9



\# Ensure canary version has 1 replica

kubectl scale deployment sample-app-v3 --replicas=1



c.

\# Verify the scaling

kubectl get deployments



Verify the traffic distribution:

\# Check all pods

kubectl get pods -l app=sample-app --show-labels



\# Test traffic distribution with multiple requests

for i in {1..20}; do

&nbsp; echo "Request $i:"

&nbsp; curl -s http://<MINIKUBE\_IP>:30080 | grep -o "Version \[0-9.]\*"

&nbsp; sleep 1

done



d. Create a monitoring script

./monitor-canary.sh



e. Gradually Increase Canary Traffic



Increase canary traffic to 25%:

\# Scale to achieve 25% canary traffic

\# Stable: 3 replicas (75%), Canary: 1 replica (25%)

kubectl scale deployment sample-app-v1 --replicas=3

kubectl scale deployment sample-app-v3 --replicas=1



Monitor the new distribution:

./monitor-canary.sh



Increase to 50% traffic split:

\# Equal distribution: 2 replicas each

kubectl scale deployment sample-app-v1 --replicas=2

kubectl scale deployment sample-app-v3 --replicas=2



Final monitoring:

./monitor-canary.sh



f. Complete Canary Rollout or Rollback



Choose your path - Complete rollout or rollback:

\# To complete the canary rollout:

./complete-canary-rollout.sh



\# OR to rollback (if issues were detected):

\# ./rollback-canary.sh



#### Advanced Monitoring



./deployment-health-check.sh



#### Trouble shooting



\# Check deployment rollout status

kubectl rollout status deployment/sample-app-v3



\# View deployment details

kubectl describe deployment sample-app-v3



\# Check pod logs

kubectl logs -l app=sample-app,version=v3



\# Check service endpoints

kubectl describe service sample-app-service



\# View resource quotas and limits

kubectl describe limitrange

kubectl describe resourcequota

