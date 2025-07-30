#### **Ingress Routing**



##### 1\. Setup ingress



\# Start minikube cluster

minikube start --driver=docker



\# Enable ingress addon

minikube addons enable ingress



\# Wait for ingress controller to be ready

kubectl wait --namespace ingress-nginx \\

  --for=condition=ready pod \\

  --selector=app.kubernetes.io/component=controller \\

  --timeout=120s



##### 2\. Generate an HTTP ingress resource



###### **A'. Create namespace**



\# Create a namespace for applications

kubectl create namespace web-apps

kubectl apply -f app1-deployment.yaml

kubectl apply -f app2-deployment.yaml



\# Verify pods are ready

kubectl wait --for=condition=ready pod -l app=app1 -n web-apps --timeout=60s

kubectl wait --for=condition=ready pod -l app=app2 -n web-apps --timeout=60s





###### **A. Generate Self-Signed TLS Certificate**



\# Create private key

openssl genrsa -out tls.key 2048



\# Create certificate signing request

openssl req -new -key tls.key -out tls.csr -subj "/CN=myapps.local/O=myapps.local"



\# Generate self-signed certificate

openssl x509 -req -days 365 -in tls.csr -signkey tls.key -out tls.crt



&nbsp;				OR



openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\

&nbsp; -keyout tls.key -out tls.crt \\

&nbsp; -subj "/CN=lab7.local/O=lab7.local" \\

&nbsp; -addext "subjectAltName=DNS:lab7.local"



\# Verify certificate

openssl x509 -in tls.crt -text -noout



\#Check the certificate details:

echo | openssl s\_client -servername lab7.local -connect localhost:8443 2>/dev/null | openssl x509 -noout -text



\#Testcert with a browser-like request:

curl -k -v -H "Host: lab7.local" https://localhost:8443/ 2>\&1 | grep -E "(SSL|TLS|certificate)"



###### **B. Create Kubernetes TLS Secret**



\# Create TLS secret

kubectl create secret tls myapps-tls-secret \\

  --cert=tls.crt \\

  --key=tls.key \\

  -n web-apps



\# Verify secret creation

kubectl get secrets -n web-apps

kubectl describe secret myapps-tls-secret -n web-apps



###### **C. Apply ingress**

kubectl apply -f ingress-basic.yaml

kubectl describe ingress web-apps-ingress -n web-apps

sleep 30



##### 3\. Configure DNS



\# Get minikube IP

MINIKUBE\_IP=$(minikube ip)

echo "Minikube IP: $MINIKUBE\_IP"



\# Add entry to hosts file (requires sudo)

echo "$MINIKUBE\_IP myapps.local" | sudo tee -a /etc/hosts

echo "$MINIKUBE\_IP api.myapps.local" | sudo tee -a /etc/hosts



\# Verify the entry was added

grep myapps.local /etc/hosts



##### 4\. Test path-based routing 

##### 

(If DNS hostname does not work use IP directly with Host header)



\# Test default path (should route to app1)

curl -H "Host: myapps.local" http://$(minikube ip)/



\# Test app1 path

curl -H "Host: myapps.local" http://$(minikube ip)/app1



\# Test app2 path

curl -H "Host: myapps.local" http://$(minikube ip)/app2



\# Alternative testing using the domain name

curl http://myapps.local/app1

curl http://myapps.local/app2



\# Test HTTPS connection (ignore certificate warnings for self-signed cert)

curl -k https://myapps.local/app1

curl -k https://myapps.local/app2



\# Test HTTP redirect to HTTPS

curl -v http://myapps.local/app1

&nbsp;	OR

curl -v -H "Host: myapps.local" http://localhost:8080/



\# Test main domain paths

curl -k -I https://myapps.local/app1

curl -k -I https://myapps.local/app2



\# Test API subdomain

curl -k -I https://api.myapps.local/



\# Check custom headers

curl -k -I https://myapps.local/app1 | grep "X-Served-By"

curl -k -I https://myapps.local/app1 | grep "X-App-Version"

##### 

##### 6\. Verify ingress resources



\# List all ingress resources

kubectl get ingress --all-namespaces



\# Check ingress class

kubectl get ingressclass



\# Verify services are accessible

kubectl get endpoints -n web-apps



\# Check pod status

kubectl get pods n web-apps -o wide

##### 

##### 7\. Load testing



\# Install apache2-utils for ab command (if not available)

sudo apt-get update \&\& sudo apt-get install -y apache2-utils



\# Perform load test on app1

ab -n 100 -c 10 -k https://myapps.local/app1



\# Perform load test on app2

ab -n 100 -c 10 -k https://myapps.local/app2

##### 

##### 8\. Monitor ingress logs



\# Get ingress controller pod name

INGRESS\_POD=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o jsonpath='{.items\[0].metadata.name}')



\# View ingress controller logs

kubectl logs -n ingress-nginx $INGRESS\_POD --tail=50



\# Follow logs in real-time (run in separate terminal)

kubectl logs -n ingress-nginx $INGRESS\_POD -f

##### 

##### 9\. Troubleshooting



**Issue 1: Ingress Controller Not Ready**



\# Check ingress controller status

kubectl get pods -n ingress-nginx

kubectl describe pod -n ingress-nginx -l app.kubernetes.io/component=controller



\# Restart ingress controller if needed

kubectl delete pod -n ingress-nginx -l app.kubernetes.io/component=controller



**Issue 2: DNS Resolution Problems**



\# Verify hosts file entries

cat /etc/hosts | grep myapps



\# Test DNS resolution

nslookup myapps.local

ping myapps.local



**Issue 3: Certificate Issues**



\# Check TLS secret

kubectl describe secret myapps-tls-secret -n web-apps



\# Verify certificate validity

openssl x509 -in tls.crt -noout -dates



**Issue 4: Service Not Accessible**



\# Check service endpoints

kubectl get endpoints -n web-apps



\# Test service directly

kubectl port-forward -n web-apps svc/app1-service 8080:80

curl http://localhost:8080

