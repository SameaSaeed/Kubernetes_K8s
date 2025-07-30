## Deploying a Multi-tier app



##### 1\. Deploy the database tier



\# Apply the ConfigMap

kubectl apply -f database-config.yaml



\# Apply the secrets



\# Apply the database deployment

kubectl apply -f database-deployment.yaml

kubectl get pods -l tier=database



\# Apply the database service o expose the database within the cluster

kubectl apply -f database-service.yaml

kubectl describe service database-service



\# Check database pod status

kubectl describe pod -l tier=database



\# Verify database service endpoints

kubectl get endpoints database-service



##### 2\. Deploy the backend tier



\# Apply the backend ConfigMap

kubectl apply -f backend-config.yaml



\# Apply the backend service

kubectl apply -f backend-service.yaml

kubectl describe service backend-service





##### 3\. Deploy the frontend tier



\# Apply the frontend ConfigMap

kubectl apply -f frontend-config.yaml



\# Apply all frontend configurations

kubectl apply -f frontend-html-config.yaml

kubectl apply -f nginx-config.yaml

kubectl apply -f frontend-deployment.yaml



\# Apply the frontend service

kubectl apply -f frontend-service.yaml



## Test 



##### A. Inter-tier communication:



\# Get a frontend pod name

FRONTEND\_POD=$(kubectl get pods -l tier=frontend -o jsonpath='{.items\[0].metadata.name}')
kubectl exec -n frontend $FRONTEND_POD -- timeout 5 bash -c "</dev/tcp/database-service.database.svc.cluster.local/3306" && echo "Connection successful" || echo "Connection failed"

\# Test frontend to backend communication

kubectl exec -it $FRONTEND\_POD -- curl -s http://backend-service:5000/api/health
                                OR
# Test connection to backend service
kubectl exec -n frontend $FRONTEND_POD -- curl -s --connect-timeout 5 backend-service.backend.svc.cluster.local

\# Test backend to database communication

BACKEND\_POD=$(kubectl get pods -l tier=backend -o jsonpath='{.items\[0].metadata.name}')
kubectl exec -it $BACKEND\_POD -- curl -s http://localhost:5000/api/data
                                OR
# Test connection to database service (using telnet to test port 3306)
kubectl exec -n backend $BACKEND_POD -- timeout 5 bash -c "</dev/tcp/database-service.database.svc.cluster.local/3306" && echo "Connection successful" || echo "Connection failed"

\# Check database connectivity from backend

kubectl exec -it $BACKEND\_POD -- curl -s http://localhost:5000/api/health



##### B. DNS Resolution \& Service Discovery



If services cannot find each other:



\# Check DNS resolution

kubectl exec -it $BACKEND\_POD -- nslookup database-service

kubectl exec -it $FRONTEND\_POD -- nslookup backend-service



\# Verify service selectors match pod labels

kubectl describe service database-service

kubectl describe service backend-service



##### C. ConfigMap Issues



* ###### **Configmap usage**



\# Check environment variables in backend pod

BACKEND\_POD=$(kubectl get pods -l tier=backend -o jsonpath='{.items\[0].metadata.name}')

kubectl exec -it $BACKEND\_POD -- env | grep -E "(DB\_|APP\_)"



\# Check ConfigMap data

kubectl get configmap database-config -o yaml

kubectl get configmap backend-config -o yaml

kubectl get configmap frontend-config -o yaml



* ###### **If the configuration is not being applied**



\# Verify ConfigMap mounting

kubectl describe pod $BACKEND\_POD | grep -A 10 "Mounts:"



\# Check environment variables

kubectl exec -it $BACKEND\_POD -- printenv | grep DB\_



##### D. Application Scaling



Test the scalability of your multi-tier application.



\# Scale frontend deployment

kubectl scale deployment frontend-deployment --replicas=5



\# Scale backend deployment

kubectl scale deployment backend-deployment --replicas=3



## Access the application



\# Get node IP and frontend service port

NODE\_IP=$(kubectl get nodes -o jsonpath='{.items\[0].status.addresses\[?(@.type=="ExternalIP")].address}')

if \[ -z "$NODE\_IP" ]; then

&nbsp;   NODE\_IP=$(kubectl get nodes -o jsonpath='{.items\[0].status.addresses\[?(@.type=="InternalIP")].address}')

fi



FRONTEND\_PORT=$(kubectl get service frontend-service -o jsonpath='{.spec.ports\[0].nodePort}')



echo "Application URL: http://$NODE\_IP:$FRONTEND\_PORT"

echo "Backend Health Check: http://$NODE\_IP:$FRONTEND\_PORT/api/health"

echo "Backend Data Endpoint: http://$NODE\_IP:$FRONTEND\_PORT/api/data"

###### 

