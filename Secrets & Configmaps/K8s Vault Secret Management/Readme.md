##### Vault Secret Management



1. ###### Set up Vault



\# Add HashiCorp Helm repository

helm repo add hashicorp https://helm.releases.hashicorp.com



\# Update Helm repositories

helm repo update



\# Create a namespace for Vault

kubectl create namespace vault



\# Install Vault in development mode (for lab purposes)

helm install vault hashicorp/vault \\

&nbsp; --namespace vault \\

&nbsp; --set "server.dev.enabled=true" \\

&nbsp; --set "server.dev.devRootToken=myroot" \\

&nbsp; --set "injector.enabled=true"



\# Uninstall Vault (If so)

helm uninstall vault -n vault

kubectl delete namespace vault



\# Wait for Vault to be ready

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault --namespace vault --timeout=300s



\# Check Vault pods

kubectl get pods -n vault



\# Check Vault pod logs

kubectl logs -n vault vault-0



\# Check Vault services

kubectl get svc -n vault



\# Port forward to access Vault UI (optional)

kubectl port-forward -n vault svc/vault 8200:8200 \&



\# To stop port-forwarding, kill any background port-forward processes

pkill -f "kubectl port-forward"



\# Set Vault environment variables

export VAULT\_ADDR='http://127.0.0.1:8200'

export VAULT\_TOKEN='myroot'



\# Download and install Vault CLI

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

sudo apt-add-repository "deb \[arch=amd64] https://apt.releases.hashicorp.com $(lsb\_release -cs) main"

sudo apt-get update \&\& sudo apt-get install vault



\# Verify Vault CLI installation

vault version



\# Check Vault status

vault status



###### 2\. Store secrets in Vault



\# Enable KV secrets engine at path 'secret'

vault secrets enable -path=secret kv-v2



\# Verify secrets engines

vault secrets list



\# Store database credentials

vault kv put secret/myapp/database \\

&nbsp; username=vaultuser \\

&nbsp; password=vaultpassword123 \\

&nbsp; host=db.example.com \\

&nbsp; port=5432



\# Store API credentials

vault kv put secret/myapp/api \\

&nbsp; key=vault-api-key-789 \\

&nbsp; secret=vault-api-secret-456 \\

&nbsp; endpoint=https://api.example.com



\# Verify secrets are stored

vault kv list secret/myapp



\# Read stored secrets

vault kv get secret/myapp/database

vault kv get secret/myapp/api



\# Enable Kubernetes auth method

vault auth enable kubernetes



\# Configure Kubernetes authentication

vault write auth/kubernetes/config \\

&nbsp; token\_reviewer\_jwt="$(kubectl exec -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \\

&nbsp; kubernetes\_host="https://kubernetes.default.svc:443" \\

&nbsp; kubernetes\_ca\_cert="$(kubectl exec -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"



\# Create policy for application secrets

vault policy write myapp-policy -



\# Verify policy creation

vault policy list

vault policy read myapp-policy



\# Create Kubernetes role

vault write auth/kubernetes/role/myapp \\

&nbsp; bound\_service\_account\_names=vault-auth \\

&nbsp; bound\_service\_account\_namespaces=default \\

&nbsp; policies=myapp-policy \\

&nbsp; ttl=1h



###### 3\. Deploy the application with vault integration



\# Apply service account for Vault authentication

kubectl apply -f ~/secrets-lab/vault-serviceaccount.yaml



\# Check Vault authentication configuration (Troubleshoot)

vault read auth/kubernetes/config



\# Create Pod with Vault annotations

kubectl apply -f ~/secrets-lab/vault-injected-pod.yaml



\# Wait for Pod to be ready (this may take a few minutes)

kubectl wait --for=condition=Ready pod/vault-injected-app --timeout=300s



\# Check Pod status

kubectl get pods



\# Check Vault agent injector logs (Troubleshoot)

kubectl logs -n vault -l app.kubernetes.io/name=vault-agent-injector



\# View injected secrets

kubectl exec -it vault-injected-app -c app -- ls -la /vault/secrets/



\# View database secrets

kubectl exec -it vault-injected-app -c app -- cat /vault/secrets/database



\# View API secrets

kubectl exec -it vault-injected-app -c app -- cat /vault/secrets/api



###### 4\. Verifying Encryption at rest and in transit



***A. Check etcd Encryption Configuration***



\# Check if encryption is enabled (in minikube)

minikube ssh -- sudo cat /etc/kubernetes/manifests/kube-apiserver.yaml | grep encryption



\# Create a test secret to verify encryption

kubectl create secret generic encryption-test --from-literal=data=sensitive-information



\# Check the secret in etcd (this shows it should be encrypted)

kubectl get secret encryption-test -o yaml



***B. Verify Base64 Encoding vs Encryption***



\# Decode the base64 encoded secret (this is NOT encryption)

kubectl get secret encryption-test -o jsonpath='{.data.data}' | base64 -d



\# Note: In a production cluster, secrets should be encrypted at rest in etcd

\# This requires configuring encryption providers in the API server



***C. Check Vault Storage Encryption***



\# Check Vault seal status (unsealed means encryption keys are available)

vault status



\# Verify that data is encrypted in Vault's storage

vault kv get -format=json secret/myapp/database



\# The data shown is the decrypted version; Vault encrypts it before storage



***D. Vault Transit Encryption***



\# Enable transit secrets engine for encryption as a service

vault secrets enable transit



\# Create an encryption key

vault write -f transit/keys/myapp-key



\# Encrypt some data

vault write transit/encrypt/myapp-key plaintext=$(echo -n "sensitive data" | base64)



\# The output shows encrypted data that can be safely stored anywhere



***E. Check TLS Configuration***



\# Verify Vault is using HTTPS (in production)

curl -k -s -o /dev/null -w "%{http\_code}" https://127.0.0.1:8200/v1/sys/health



\# Check Kubernetes API server TLS

kubectl config view --minify --flatten -o jsonpath='{.clusters\[0].cluster.server}'



***F. Test Secure Communication***



\# Deploy and check a Pod that communicates with Vault over HTTPS

kubectl apply -f ~/secrets-lab/secure-comm-test.yaml

kubectl logs secure-comm-test -f



###### 5\. Implementing Best Practices



###### A. Secret Rotation



**Step 1: Update Secrets in Vault**



\# Update database password in Vault

vault kv put secret/myapp/database \\

&nbsp; username=vaultuser \\

&nbsp; password=newrotatedpassword456 \\

&nbsp; host=db.example.com \\

&nbsp; port=5432



\# Verify the update

vault kv get secret/myapp/database



**Step 2: Force Pod Restart to Get New Secrets**



\# Delete and recreate the Vault-injected Pod to get new secrets

kubectl delete pod vault-injected-app



\# Recreate the Pod

kubectl apply -f ~/secrets-lab/vault-injected-pod.yaml



\# Wait for it to be ready

kubectl wait --for=condition=Ready pod/vault-injected-app --timeout=300s



\# Verify new secrets are loaded

kubectl exec -it vault-injected-app -c app -- cat /vault/secrets/database



###### B. Implement Secret Scanning



\#Check for Hardcoded Secrets

chmod +x ~/secrets-lab/secret-scanner.sh

~/secrets-lab/secret-scanner.sh



###### C. Monitor Secret Access



\# Enable file audit device in Vault

vault audit enable file file\_path=/vault/logs/audit.log



\# Perform some secret operations to generate audit logs

vault kv get secret/myapp/database

vault kv get secret/myapp/api



\# Check audit logs (in a real environment)

kubectl exec -n vault vault-0 -- tail -f /vault/logs/audit.log

