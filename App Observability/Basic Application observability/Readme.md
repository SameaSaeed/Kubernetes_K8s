**App with probes**



kubectl apply -f app-with-probes.yaml	(deployment)

kubectl apply -f webapp-service.yaml

kubectl describe pods -l app=webapp	(probe status)



kubectl apply -f failing-probes.yaml	(pod)

kubectl describe pod failing-webapp

kubectl get pods failing-webapp -w	(Watch the pod restart due to liveness probe failure)



**Monitor Node Resource Usage**



Step 1: View node resource usage

kubectl top nodes



Step 2: Get detailed node information

kubectl describe nodes



Step 3: Monitor nodes continuously

watch kubectl top nodes

Press Ctrl+C to stop watching.



**Monitor Node Resource Usage**



Step 1: View node resource usage

kubectl top nodes



Step 2: Get detailed node information

kubectl describe nodes



Step 3: Monitor nodes continuously

watch kubectl top nodes

Press Ctrl+C to stop watching.



**Monitor Pod Resource Usage**



Step 1: View pod resource usage across all namespaces

kubectl top pods --all-namespaces



Step 2: View pod resource usage in current namespace

kubectl top pods



Step 3: Sort pods by CPU usage

kubectl top pods --sort-by=cpu



Step 4: Sort pods by memory usage

kubectl top pods --sort-by=memory



Step 5: Monitor specific pods

kubectl top pods -l app=webapp



**Analyze Application Logs and Debug with kubectl**



Step 1: View logs from webapp pods

kubectl logs -l app=webapp



Step 2: View logs from a specific pod



\# Get pod name first

POD\_NAME=$(kubectl get pods -l app=webapp -o jsonpath='{.items\[0].metadata.name}')

kubectl logs $POD\_NAME



\#Filter logs using grep (in a new terminal)

kubectl logs logging-app | grep ERROR

kubectl logs logging-app | grep WARNING



Step 3: Follow logs in real-time

kubectl logs -f $POD\_NAME

Press Ctrl+C to stop following logs.



Step 4: View logs from previous container instance (if pod restarted)

kubectl logs $POD\_NAME --previous



Step 5: View logs with timestamps

kubectl logs $POD\_NAME --timestamps



Step 6: View recent logs (last 10 lines)

kubectl logs $POD\_NAME --tail=10



Step 7: View logs from specific of the multi-containers 

kubectl logs multi-container-app -c web-server

kubectl logs multi-container-app -c log-processor



\#Follow logs from both containers

kubectl logs -f multi-container-app -c web-server \&

kubectl logs -f multi-container-app -c log-processor \&



\#Stop the background processes

jobs

kill %1 %2



**Debug Applications using kubectl exec**



Copy files from container to local machine

kubectl exec $POD\_NAME -- cat /etc/nginx/nginx.conf > nginx-config-backup.conf



Execute multiple commands

kubectl exec $POD\_NAME -- sh -c "echo 'Debug info:'; date; whoami; pwd"



