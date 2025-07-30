#### **CRD**



##### 1\. Setting up



List all available API resources in your cluster:

kubectl api-resources



Check the current API versions:

kubectl api-versions



Examine a standard Kubernetes resource definition:

kubectl get deployments -o yaml | head -20



##### 2\. Create Your First Custom Resource Definition



Apply the CRD to your cluster:

kubectl apply -f webapp-crd.yaml



Verify the CRD was created successfully:

kubectl get crd webapps.example.com



Check that the new resource type is now available:

kubectl api-resources | grep webapp



##### 3\. Create Custom Resource Instances



Apply the custom resource:

kubectl apply -f sample-webapp.yaml



Verify the custom resource was created:

kubectl get webapps

kubectl get wa  # Using the short name



Examine the custom resource in detail:

kubectl describe webapp my-web-application



View the resource in YAML format:

kubectl get webapp my-web-application -o yaml



##### 4\. Create a Basic Controller Script



###### **a. Make exe**

chmod +x webapp-controller.py



###### **b. Deploy the Controller as a Kubernetes Deployment**

kubectl create configmap webapp-controller-script --from-file=webapp-controller.py

kubectl apply -f controller-deployment.yaml

kubectl get pods -l app=webapp-controller

kubectl logs -l app=webapp-controller -f



##### 5\. Test the Controller Manually



python3 --version



Run the controller in the background:

python3 webapp-controller.py \&

CONTROLLER\_PID=$!

echo "Controller running with PID: $CONTROLLER\_PID"



Monitor the controller output:

\# The controller will show its activity in the terminal

\# Let it run for about 1 minute to see it working



##### 6\. Verify Custom Resource Functionality



###### **a. Test Basic Functionality**



Check if the controller created resources for our WebApp:

kubectl get deployments

kubectl get services

kubectl get pods



Verify the WebApp status was updated:

kubectl get webapp my-web-application -o yaml | grep -A 10 status



Check the deployment details:

kubectl describe deployment my-web-application-deployment



###### **b. Test Scaling Operations**



Apply the new WebApp:

kubectl apply -f test-webapp.yaml



Wait for the controller to process it (about 30 seconds), then check:

kubectl get webapps

kubectl get deployments

kubectl get pods



Scale the original WebApp:

kubectl patch webapp my-web-application --type='merge' -p='{"spec":{"replicas":5}}'



Wait and verify the scaling worked:

\# Wait about 30 seconds for the controller to reconcile

sleep 30

kubectl get webapp my-web-application -o yaml | grep replicas

kubectl get deployment my-web-application-deployment



###### **c. Test Resource Deletion**



Delete one of the WebApps:

kubectl delete webapp test-application



Verify the associated resources still exist (our controller doesn't handle deletion):

kubectl get deployment test-application-deployment

kubectl get service test-application-service



Clean up the orphaned resources manually:

kubectl delete deployment test-application-deployment

kubectl delete service test-application-service



###### **d. Advanced Testing**



Try to apply the invalid resource:

kubectl apply -f invalid-webapp.yaml

Note: The resource creation should fail due to our validation schema.



Try to apply the incomplete resource:

kubectl apply -f incomplete-webapp.yaml



##### 7\. Monitoring



**Monitor Controller Activity**

\# If running the controller manually

jobs

\# You should see the controller job running



\# If using the deployment

kubectl logs -l app=webapp-controller --tail=50



**Monitor resource events:**

kubectl get events --sort-by=.metadata.creationTimestamp



**Check WebApp resource status:**

kubectl get webapps -o wide



##### 8\. Troubleshooting



Check CRD validation:

kubectl describe crd webapps.example.com



Verify RBAC permissions:

kubectl auth can-i get webapps --as=system:serviceaccount:default:webapp-controller

kubectl auth can-i create deployments --as=system:serviceaccount:default:webapp-controller



Debug controller issues:

\# Check if controller pod is running

kubectl get pods -l app=webapp-controller



\# Check controller logs for errors

kubectl logs -l app=webapp-controller --previous



##### 9\. Performance and Resource Usage



Check resource usage:

kubectl top pods -l app=webapp-controller



Monitor WebApp resources:

kubectl get webapps --watch



Check cluster resource usage:

kubectl get nodes

kubectl describe node $(kubectl get nodes -o jsonpath='{.items\[0].metadata.name}')

