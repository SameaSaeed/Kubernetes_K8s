#### **Cluster Backup and Restore Lab**



1. ##### Setup



\# Find etcd configuration

sudo find /etc/kubernetes -name "\*etcd\*" -type f



\# Examine etcd manifest

sudo cat /etc/kubernetes/manifests/etcd.yaml | grep -E "(cert|key|endpoint)"



\# Set etcd endpoint

export ETCDCTL\_API=3

export ETCD\_ENDPOINT="https://127.0.0.1:2379"



\# Set certificate paths (adjust paths based on your cluster)

export ETCD\_CACERT="/etc/kubernetes/pki/etcd/ca.crt"

export ETCD\_CERT="/etc/kubernetes/pki/etcd/server.crt"

export ETCD\_KEY="/etc/kubernetes/pki/etcd/server.key"



##### 2\. Deploy app



\# Create a test namespace

kubectl create namespace backup-test



\# Create a sample deployment

kubectl apply -f deployment.yaml



\# Create a ConfigMap

kubectl create configmap test-config \\

&nbsp; --from-literal=database\_url="postgresql://localhost:5432/testdb" \\

&nbsp; --from-literal=debug\_mode="true" \\

&nbsp; -n backup-test



\# Create a Secret

kubectl create secret generic test-secret \\

&nbsp; --from-literal=username="admin" \\

&nbsp; --from-literal=password="secretpassword123" \\

&nbsp; -n backup-test

Subtask 2.3: Verify Test Resources

\# List all resources in test namespace

kubectl get all -n backup-test



\# Verify ConfigMap and Secret

kubectl get configmap,secret -n backup-test



\# Check deployment status

kubectl rollout status deployment/test-app -n backup-test



##### 3\. Perform Full Cluster Backup Using etcdctl



\# Create backup directory

sudo mkdir -p /opt/etcd-backup

sudo chmod 755 /opt/etcd-backup



\# Create backup with timestamp

BACKUP\_DATE=$(date +%Y%m%d\_%H%M%S)

BACKUP\_FILE="/opt/etcd-backup/etcd-backup-${BACKUP\_DATE}.db"



\# Create etcd snapshot backup

sudo etcdctl snapshot save $BACKUP\_FILE \\

&nbsp; --endpoints=$ETCD\_ENDPOINT \\

&nbsp; --cacert=$ETCD\_CACERT \\

&nbsp; --cert=$ETCD\_CERT \\

&nbsp; --key=$ETCD\_KEY



\# Verify backup file was created

ls -la /opt/etcd-backup/

Subtask 3.3: Verify Backup Integrity

\# Check backup status and integrity

sudo etcdctl snapshot status $BACKUP\_FILE \\

&nbsp; --write-out=table



\# Get detailed backup information

sudo etcdctl snapshot status $BACKUP\_FILE \\

&nbsp; --write-out=json | jq '.'



##### 4\. Simulate Disaster by Deleting Critical Resources



\# Save current cluster state for comparison

kubectl get all --all-namespaces > /tmp/cluster-state-before.txt



\# Count total resources

echo "Total pods before deletion:"

kubectl get pods --all-namespaces --no-headers | wc -l



\# Delete our test namespace and all its resources

kubectl delete namespace backup-test



\# Verify deletion

kubectl get namespace backup-test

kubectl get all -n backup-test



\# Delete a system ConfigMap (we'll restore this)

kubectl delete configmap coredns -n kube-system



\# Verify the ConfigMap is gone

kubectl get configmap coredns -n kube-system





##### 5\. Restore Cluster from Backup



1. **Stop etcd Service**

Important: This step requires careful execution as it will temporarily make the cluster unavailable.



\# Move the current etcd manifest to stop the etcd pod

sudo mv /etc/kubernetes/manifests/etcd.yaml /etc/kubernetes/etcd.yaml.backup



\# Wait for etcd pod to stop

sleep 30



\# Verify etcd pod is stopped

kubectl get pods -n kube-system | grep etcd || echo "etcd pod stopped"



**2. Restore etcd Data**

\# Remove existing etcd data directory

sudo rm -rf /var/lib/etcd



\# Restore from backup

sudo etcdctl snapshot restore $BACKUP\_FILE \\

&nbsp; --data-dir=/var/lib/etcd \\

&nbsp; --initial-cluster-token=etcd-cluster-1 \\

&nbsp; --initial-advertise-peer-urls=https://127.0.0.1:2380 \\

&nbsp; --name=master \\

&nbsp; --initial-cluster=master=https://127.0.0.1:2380



\# Set proper ownership

sudo chown -R etcd:etcd /var/lib/etcd



**3. Restart etcd Service**



\# Restore etcd manifest to restart the service

sudo mv /etc/kubernetes/etcd.yaml.backup /etc/kubernetes/manifests/etcd.yaml



\# Wait for etcd to start

sleep 60



\# Check if etcd pod is running

kubectl get pods -n kube-system | grep etcd



##### 6\. Verify Cluster Restoration



1. **Check Cluster Health**



\# Wait for cluster to be ready

sleep 30



\# Check cluster info

kubectl cluster-info



\# Verify all nodes are ready

kubectl get nodes



\# Check system pods

kubectl get pods -n kube-system





**2. Verify Restored Resources**



\# Check if our test namespace was restored

kubectl get namespace backup-test



\# Verify test application was restored

kubectl get all -n backup-test



\# Check ConfigMap and Secret restoration

kubectl get configmap,secret -n backup-test



\# Verify the system ConfigMap was restored

kubectl get configmap coredns -n kube-system



**3. Test Application Functionality**



\# Check deployment status

kubectl rollout status deployment/test-app -n backup-test



\# Get pod details

kubectl get pods -n backup-test -o wide



\# Test if pods are running correctly

kubectl describe deployment test-app -n backup-test



\# Verify ConfigMap contents

kubectl get configmap test-config -n backup-test -o yaml

##### 

##### 7\. Validate Complete Cluster Functionality



\# Create a new deployment to test cluster functionality

kubectl apply -f post-restore-test.yaml



\# Verify new deployment

kubectl get deployment post-restore-test -n backup-test



\# Test scaling

kubectl scale deployment test-app --replicas=3 -n backup-test



\# Verify scaling worked

kubectl get pods -n backup-test



\# Test service creation

kubectl expose deployment test-app --port=80 --type=ClusterIP -n backup-test



\# Verify service

kubectl get service -n backup-test



##### 8\. Compare Pre and Post Restore State



\# Save current cluster state

kubectl get all --all-namespaces > /tmp/cluster-state-after.txt



\# Count total pods after restoration

echo "Total pods after restoration:"

kubectl get pods --all-namespaces --no-headers | wc -l



\# Compare states (optional)

echo "Cluster state comparison available in:"

echo "Before: /tmp/cluster-state-before.txt"

echo "After: /tmp/cluster-state-after.txt"



##### 9\. Implement Backup Best Practices



\# Create backup script

sudo tee /opt/etcd-backup/backup-script.sh



\# Make script executable

sudo chmod +x /opt/etcd-backup/backup-script.sh



\# Run the backup script

sudo /opt/etcd-backup/backup-script.sh



\# Verify new backup was created

ls -la /opt/etcd-backup/



\# Create restore script template

sudo tee /opt/etcd-backup/restore-script.sh



\# Set ownership

chown -R etcd:etcd /var/lib/etcd



\# Restart etcd

echo "Restarting etcd..."

mv /etc/kubernetes/etcd.yaml.backup /etc/kubernetes/manifests/etcd.yaml



echo "Restore completed. Please wait for cluster to be ready..."

EOF



\# Make script executable

sudo chmod +x /opt/etcd-backup/restore-script.sh



##### 11\. Troubleshooting 



**Issue 1: etcdctl Command Not Found**



\# Install etcdctl if missing

ETCD\_VER=v3.5.9

curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD\_VER}/etcd-${ETCD\_VER}-linux-amd64.tar.gz -o /tmp/etcd-${ETCD\_VER}-linux-amd64.tar.gz

sudo tar xzf /tmp/etcd-${ETCD\_VER}-linux-amd64.tar.gz -C /tmp/

sudo mv /tmp/etcd-${ETCD\_VER}-linux-amd64/etcdctl /usr/local/bin/



**Issue 2: Certificate Permission Errors**



\# Check certificate permissions

sudo ls -la /etc/kubernetes/pki/etcd/



\# Fix permissions if needed

sudo chmod 644 /etc/kubernetes/pki/etcd/\*.crt

sudo chmod 600 /etc/kubernetes/pki/etcd/\*.key



**Issue 3: Cluster Not Responding After Restore**



\# Check etcd logs

sudo journalctl -u kubelet -f



\# Check etcd pod logs

kubectl logs -n kube-system $(kubectl get pods -n kube-system | grep etcd | awk '{print $1}')



\# Restart kubelet if needed

sudo systemctl restart kubelet

