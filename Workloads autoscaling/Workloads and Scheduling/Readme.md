##### Workloads and Scheduling



A. Apply autoscaler

kubectl apply -f nginx-deployment.yaml

kubectl apply -f nginx-service.yaml

kubectl apply -f cpu-demo-deployment.yaml

kubectl apply -f cpu-demo-hpa.yaml



B. Test Autoscaling Behavior



Monitor HPA status:

kubectl get hpa -w



Keep this running in one terminal window.

In a new terminal, generate CPU load:

kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh



Inside the load generator pod, run:

while true; do wget -q -O- http://cpu-demo-service/; done



Create a service for the CPU demo first (in another terminal):

kubectl expose deployment cpu-demo --port=80 --target-port=8080 --name=cpu-demo-service



Watch the scaling in action:

kubectl get pods -l app=cpu-demo -w



Stop the load generator by pressing Ctrl+C and exit the pod.



Observe scale-down behavior:

kubectl get hpa

kubectl get pods -l app=cpu-demo



C. Perform rolling update



kubectl apply -f webapp-deployment.yaml

kubectl expose deployment webapp --port=80 --type=ClusterIP



Check current image version:

kubectl describe deployment webapp | grep Image



Update the deployment to use a newer nginx version:

kubectl set image deployment/webapp webapp=nginx:1.21



Monitor the rolling update process:

kubectl rollout status deployment/webapp



Watch pods during the update:

kubectl get pods -l app=webapp -w

Press Ctrl+C after observing the rolling update process.



Verify the update completed successfully:

kubectl describe deployment webapp | grep Image

kubectl get pods -l app=webapp



Check rollout history:

kubectl rollout history deployment/webapp



Get detailed information about a specific revision:

kubectl rollout history deployment/webapp --revision=1

kubectl rollout history deployment/webapp --revision=2



Perform another update with a problematic image:

kubectl set image deployment/webapp webapp=nginx:1.22-invalid



Monitor the failed update:

kubectl rollout status deployment/webapp --timeout=60s



Check the status of pods:

kubectl get pods -l app=webapp

kubectl describe pods -l app=webapp | grep -A 5 Events



Rollback to the previous working version:

kubectl rollout undo deployment/webapp



Monitor the rollback process:

kubectl rollout status deployment/webapp



Verify rollback success:

kubectl get pods -l app=webapp

kubectl describe deployment webapp | grep Image



Rollback to a specific revision:

kubectl rollout undo deployment/webapp --to-revision=1



Verify the specific rollback:

kubectl rollout status deployment/webapp

kubectl describe deployment webapp | grep Image



D. Workload Management



kubectl create namespace resource-demo

kubectl apply -f resource-quota.yaml

kubectl describe quota compute-quota -n resource-demo



kubectl apply -f resource-limited-deployment.yaml

kubectl describe quota compute-quota -n resource-demo

