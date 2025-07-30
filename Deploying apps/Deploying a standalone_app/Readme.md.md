**A. Create a ConfigMap with the  HTML**

kubectl create configmap nginx-html --from-file=index.html=index.html



**B. Deploy the app**



1\. Create the application deployment manifest

nano nginx-deployment.yaml

Copy and paste the respective YAML content



2\. Deploy the application

kubectl apply -f nginx-deployment.yaml



3\. Verify application details

kubectl describe deployment nginx-standalone-app

kubectl get replicasets -l app=nginx-standalone



**C. Expose the application externally using a NodePort service**



1. Create a service manifest file

nano nginx-service.yaml

Copy and paste the respective YAML content



2\. Deploy the Service

kubectl apply -f nginx-service.yaml



3\. Test External Access

minikube ip

curl http://$(minikube ip):30080 or echo "Access your application at: http://$(minikube ip):30080"



**D. Verify Service Endpoints**



1. Check the service endpoints to ensure they're pointing to your pods:

kubectl get endpoints nginx-standalone-service



2\. Compare the endpoint IPs with your pod IPs:

kubectl get pods -l app=nginx-standalone -o wide



