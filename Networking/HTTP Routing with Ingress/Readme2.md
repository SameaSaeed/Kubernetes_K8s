###### Ingress Routing



1\. Deploy web-application with a ClusterIP and a load balancer service and another deployment for path-based routing



2\. #Check if NGINX Ingress Controller is installed:

&nbsp;  kubectl get pods -n ingress-nginx



&nbsp;  #If not installed, install NGINX Ingress Controller:

&nbsp;  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller       v1.8.2/deploy/static/provider/cloud/deploy.yaml



3\. Create an HTTP \& HTTPS ingress resource with TLS cert and K8s secret 

4\. Add entries in DNS hostname file

5\. Test path based routing as mentioned in other file.



