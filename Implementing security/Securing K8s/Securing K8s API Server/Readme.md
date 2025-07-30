##### **Securing the API Server**



**1. Create a certified user**



\#Generate a private key for our test user:

openssl genrsa -out testuser.key 2048



\#Create a certificate signing request (CSR):

openssl req -new -key testuser.key -out testuser.csr -subj "/CN=testuser/O=developers"



\#Create a Kubernetes CSR object

kubectl apply -f CertificateSigningRequest.yaml



\#Approve the certificate signing request:

kubectl certificate approve testuser-csr



\#Extract the signed certificate:

kubectl get csr testuser-csr -o jsonpath='{.status.certificate}' | base64 -d > testuser.crt



**2. Create and test a custom role with limited permissions**



\#Create a role that only allows reading pods in the security-lab namespace:

kubectl apply -f pod-reader.yaml



\#Create a role binding to associate the user with the role:

kubectl apply -f read-pods.yaml



\#Configure kubectl to use the new user credentials:

kubectl config set-credentials testuser --client-certificate=testuser.crt --client-key=testuser.key

kubectl config set-context testuser-context --cluster=kubernetes --user=testuser



\#Create a test pod in the security-lab namespace using admin privileges:

kubectl create deployment nginx-test --image=nginx --replicas=1 -n security-lab



\#Switch to the testuser context and test permissions:

kubectl config use-context testuser-context



\# Check what the user can do

kubectl auth can-i --list --as=testuser -n security-lab



\#Test allowed operations (should work):

kubectl get pods -n security-lab



\#Test forbidden operations (should fail):

kubectl get pods -n default

kubectl delete pod -n security-lab --all

kubectl create deployment test --image=nginx -n security-lab



\#Switch back to admin context:

kubectl config use-context kubernetes-admin@kubernetes



**3. Enable API Server Encryption for Sensitive Data**



\#Generate an encryption key:

head -c 32 /dev/urandom | base64



\#Create the encryption configuration file:

mkdir -p /etc/kubernetes \&\& cd /etc/kubernetes

kubectl apply -f encryption-config.yaml



\#Backup the current API server manifest:

sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml.backup



\#Edit the API server configuration to enable encryption:

sudo nano /etc/kubernetes/manifests/kube-apiserver.yaml



\#Add the encryption configuration to the API server arguments: Add this line under the command section:

\- --encryption-provider-config=/etc/kubernetes/encryption-config.yaml



\#Add the volume mount for the encryption config: Add under volumeMounts:

\- mountPath: /etc/kubernetes/encryption-config.yaml

&nbsp; name: encryption-config

&nbsp; readOnly: true



\#Add the volume definition: Add under volumes:

\- hostPath:

&nbsp;   path: /etc/kubernetes/encryption-config.yaml

&nbsp;   type: File

&nbsp; name: encryption-config



\# Verify encryption config file syntax (Troubleshooting)

sudo cat /etc/kubernetes/encryption-config.yaml



\#Wait for the API server to restart (this happens automatically):

kubectl get pods -n kube-system | grep kube-apiserver



\# Check API server logs (Troubleshooting)

sudo journalctl -u kubelet | grep apiserver



\#Create a test secret:

kubectl create secret generic test-secret --from-literal=password=supersecret -n security-lab



\#Verify the secret is encrypted in etcd:

sudo ETCDCTL\_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \\

&nbsp; --cacert=/etc/kubernetes/pki/etcd/ca.crt \\

&nbsp; --cert=/etc/kubernetes/pki/etcd/server.crt \\

&nbsp; --key=/etc/kubernetes/pki/etcd/server.key \\

&nbsp; get /registry/secrets/security-lab/test-secret | hexdump -C



\#Force re-encryption of all existing secrets:

kubectl get secrets --all-namespaces -o json | kubectl replace -f -



\#Verify encryption of existing secrets:

kubectl get secret -n kube-system | head -5



\# Restore backup if needed

sudo cp /etc/kubernetes/manifests/kube-apiserver.yaml.backup /etc/kubernetes/manifests/kube-apiserver.yaml



**4. Implement TLS certificate to secure API communication**



\#Check current API server certificate:

sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 5 "Subject:"



\#Verify certificate validity:

sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates



\#Check certificate subject alternative names:

sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 5 "Subject Alternative Name"



\# Generate CA private key

mkdir -p ~/custom-certs

cd ~/custom-certs

openssl genrsa -out ca.key 4096



\# Generate CA certificate

openssl req -new -x509 -key ca.key -sha256 -subj "/C=US/ST=CA/O=MyOrg/CN=MyCA" -days 3650 -out ca.crt



\# Generate private key for API server

openssl genrsa -out apiserver-custom.key 4096



\# Create certificate signing request

openssl req -new -key apiserver-custom.key -out apiserver-custom.csr -subj "/C=US/ST=CA/O=MyOrg/CN=kubernetes-api"



\#Sign the certificate with our custom CA:

openssl x509 -req -in apiserver-custom.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out apiserver-custom.crt -days 365 -extensions v3\_req -extfile apiserver-custom.ext



\# Generate client private key

openssl genrsa -out client.key 4096



\# Create client certificate signing request

openssl req -new -key client.key -out client.csr -subj "/C=US/ST=CA/O=MyOrg/CN=api-client"



\# Sign client certificate

openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 365



\# Verify certificate chain

openssl verify -CAfile ca.crt apiserver-custom.crt

openssl verify -CAfile ca.crt client.crt



\# Test API server accessibility with proper certificates

curl --cacert ca.crt --cert client.crt --key client.key https://127.0.0.1:6443/api/v1/namespaces



\#Run the certificate expiry check

chmod +x check-cert-expiry.sh

./check-cert-expiry.sh



Troubleshooting:

LS handshake failures or certificate verification errors.



\# Check certificate validity

openssl x509 -in /path/to/cert.crt -noout -dates



\# Verify certificate chain

openssl verify -CAfile ca.crt client.crt



\# Check certificate subject alternative names

openssl x509 -in /path/to/cert.crt -text -noout | grep -A 5 "Subject Alternative Name"





**5. Verification \& Testing**



chmod +x security-test.sh

./security-test.sh



