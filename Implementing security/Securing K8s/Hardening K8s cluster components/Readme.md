##### Hardening the Controller Manager



\#Check the current Controller Manager status:

sudo systemctl status kube-controller-manager



\#Examine the Controller Manager configuration file:

sudo cat /etc/kubernetes/manifests/kube-controller-manager.yaml



\#View current Controller Manager logs:

sudo journalctl -u kube-controller-manager -n 50



\#Create a dedicated directory for Controller Manager certificates:

sudo mkdir -p /etc/kubernetes/pki/controller-manager

sudo chmod 700 /etc/kubernetes/pki/controller-manager



\# Create private key

sudo openssl genrsa -out /etc/kubernetes/pki/controller-manager/controller-manager.key 2048



\# Create client certificate signing request

sudo openssl req -new -key /etc/kubernetes/pki/controller-manager/controller-manager.key \\

&nbsp; -out /etc/kubernetes/pki/controller-manager/controller-manager.csr \\

&nbsp; -subj "/CN=system:kube-controller-manager"



\# Sign the certificate

sudo openssl x509 -req -in /etc/kubernetes/pki/controller-manager/controller-manager.csr \\

&nbsp; -CA /etc/kubernetes/pki/ca.crt \\

&nbsp; -CAkey /etc/kubernetes/pki/ca.key \\

&nbsp; -CAcreateserial \\

&nbsp; -out /etc/kubernetes/pki/controller-manager/controller-manager.crt \\

&nbsp; -days 365



\# Set proper permissions on certificates:

sudo chmod 600 /etc/kubernetes/pki/controller-manager/controller-manager.key

sudo chmod 644 /etc/kubernetes/pki/controller-manager/controller-manager.crt

sudo chown root:root /etc/kubernetes/pki/controller-manager/\*



\# Create a backup of the current configuration:

sudo cp /etc/kubernetes/manifests/kube-controller-manager.yaml \\

&nbsp; /etc/kubernetes/manifests/kube-controller-manager.yaml.backup



\# Create hardened Controller Manager configuration

cd /etc/kubernetes/manifests

kubectl apply -f kube-controller-manager.yaml



\# Wait for pod to restart

sleep 30



\# Check if Controller Manager is running

kubectl get pods -n kube-system | grep controller-manager



\# Verify the hardened configuration

kubectl logs -n kube-system kube-controller-manager-$(hostname) | tail -20



##### Hardening the Scheduler



\#Create backup of current Scheduler configuration:

sudo cp /etc/kubernetes/manifests/kube-scheduler.yaml \\

&nbsp; /etc/kubernetes/manifests/kube-scheduler.yaml.backup



\#Create hardened Scheduler configuration:

sudo tee /etc/kubernetes/manifests/kube-scheduler.yaml > /dev/null <<EOF ... EOF



\# Wait for restart

sleep 30



\# Check Scheduler pod status

kubectl get pods -n kube-system | grep scheduler



\# Verify Scheduler logs

kubectl logs -n kube-system kube-scheduler-$(hostname) | tail -10



##### Enable authentication and authorization for kubelet



\#Check current Kubelet configuration:

sudo cat /var/lib/kubelet/config.yaml



\#Create enhanced Kubelet configuration with authentication:

sudo tee /var/lib/kubelet/config.yaml > /dev/null <<EOF



\#Create RBAC configuration for Kubelet:

kubectl apply -f - <<EOF … EOF



\#Restart Kubelet service:

sudo systemctl restart kubelet





\# Check Kubelet status

sudo systemctl status kubelet



\#Verify Kubelet authentication configuration:

curl -k https://localhost:10250/metrics



Test Kubelet Security

Test anonymous access (should be denied):

\# This should fail with authentication error

curl -k https://localhost:10250/pods

Test with proper authentication:

\# Create a test certificate for authentication

sudo openssl genrsa -out /tmp/kubelet-client.key 2048

sudo openssl req -new -key /tmp/kubelet-client.key \\

&nbsp; -out /tmp/kubelet-client.csr \\

&nbsp; -subj "/CN=kubelet-api"



sudo openssl x509 -req -in /tmp/kubelet-client.csr \\

&nbsp; -CA /etc/kubernetes/pki/ca.crt \\

&nbsp; -CAkey /etc/kubernetes/pki/ca.key \\

&nbsp; -CAcreateserial \\

&nbsp; -out /tmp/kubelet-client.crt \\

&nbsp; -days 365



\# Test with client certificate

curl -k --cert /tmp/kubelet-client.crt --key /tmp/kubelet-client.key \\

&nbsp; https://localhost:10250/metrics | head -10

