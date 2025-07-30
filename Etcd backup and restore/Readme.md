##### **Backup and restore**



1. ###### etcd Setup



\# Install etcdctl

ETCD\_VER=v3.5.0

wget https://github.com/etcd-io/etcd/releases/download/${ETCD\_VER}/etcd-${ETCD\_VER}-linux-amd64.tar.gz

tar xzf etcd-${ETCD\_VER}-linux-amd64.tar.gz

sudo mv etcd-${ETCD\_VER}-linux-amd64/etcdctl /usr/local/bin/



\# Check etcdctl version

etcdctl version



\# Verify certificate paths

ls -la /etc/kubernetes/pki/etcd/



\# Check certificate validity

openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -text -noout



\# Set environment variables for etcdctl

export ETCDCTL\_API=3

export ETCDCTL\_CACERT=/etc/kubernetes/pki/etcd/ca.crt

export ETCDCTL\_CERT=/etc/kubernetes/pki/etcd/server.crt

export ETCDCTL\_KEY=/etc/kubernetes/pki/etcd/server.key



\# Verify etcd connectivity

etcdctl endpoint health



\# Find etcd pod

kubectl get pods -n kube-system | grep etcd



\# Get detailed information about etcd pod

kubectl describe pod -n kube-system etcd-$(hostname)



\# Check etcd static pod manifest

sudo cat /etc/kubernetes/manifests/etcd.yaml



###### 2\. Create sample-app, configmap, secret and a service



\# Create a ConfigMap

kubectl create configmap test-config \\

&nbsp; --from-literal=database.host=mysql.example.com \\

&nbsp; --from-literal=database.port=3306 \\

&nbsp; -n backup-test



\# Create a Secret

kubectl create secret generic test-secret \\

&nbsp; --from-literal=username=admin \\

&nbsp; --from-literal=password=secretpassword \\

&nbsp; -n backup-test



###### 3.Perform Etcd Snapshot Backup



\# Create backup directory

sudo mkdir -p /opt/etcd-backup



\# Set appropriate permissions

sudo chmod 755 /opt/etcd-backup



\# Change to backup directory

cd /opt/etcd-backup



\# Create snapshot with timestamp

BACKUP\_FILE="/opt/etcd-backup/etcd-snapshot-$(date +%Y%m%d-%H%M%S).db"



sudo etcdctl snapshot save $BACKUP\_FILE \\

  --endpoints=https://127.0.0.1:2379 \\

  --cacert=/etc/kubernetes/pki/etcd/ca.crt \\

  --cert=/etc/kubernetes/pki/etcd/server.crt \\

  --key=/etc/kubernetes/pki/etcd/server.key



\# Verify snapshot was created

ls -la /opt/etcd-backup/



\# Verify snapshot status

sudo etcdctl snapshot status $BACKUP\_FILE \\

  --write-out=table



\# Check snapshot file size and permissions

ls -lh $BACKUP\_FILE



\# Store backup file path for later use

echo "export BACKUP\_FILE=$BACKUP\_FILE" >> ~/.bashrc

source ~/.bashrc



*Troubleshoot: If you get permission errors:*



\# Run commands with sudo

sudo etcdctl snapshot save /opt/etcd-backup/snapshot.db



\# Check file permissions

sudo chown -R $(whoami):$(whoami) /opt/etcd-backup/



###### 4\. Simulate cluster failure



\# Save current state to file

kubectl get all -n backup-test > /tmp/pre-failure-state.txt



\# Delete the test namespace (this will remove all resources in it)

kubectl delete namespace backup-test



\# Verify deletion

kubectl get namespaces | grep backup-test

kubectl get pods -n backup-test 2>/dev/null || echo "Namespace deleted successfully"



\# Delete some system resources (be careful in production!)

kubectl delete configmap -n kube-system coredns --ignore-not-found=true



\# Try to access deleted resources

kubectl get all -n backup-test



\# Check if any system components are affected

kubectl get pods -n kube-system



\# Document the failure state

echo "=== Post-Failure State ==="

kubectl get namespaces

kubectl get all --all-namespaces | wc -l



###### 5\. Store from etcd snapshot



\# Move static pod manifests to stop them

sudo mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/

sudo mv /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/

sudo mv /etc/kubernetes/manifests/kube-scheduler.yaml /tmp/

sudo mv /etc/kubernetes/manifests/etcd.yaml /tmp/



\# Wait for pods to stop

sleep 30



\# Verify pods are stopped

docker ps | grep -E "(kube-apiserver|kube-controller|kube-scheduler|etcd)" || echo "Components stopped"



\# Create backup of current etcd data directory

sudo mv /var/lib/etcd /var/lib/etcd.backup.$(date +%Y%m%d-%H%M%S)



\# Create new etcd data directory

sudo mkdir -p /var/lib/etcd



\# Restore etcd from snapshot

sudo etcdctl snapshot restore $BACKUP\_FILE \\

  --data-dir=/var/lib/etcd \\

  --name=master \\

  --initial-cluster=master=https://127.0.0.1:2380 \\

  --initial-advertise-peer-urls=https://127.0.0.1:2380



\# Set correct ownership for etcd data

sudo chown -R etcd:etcd /var/lib/etcd



\# Restore static pod manifests

sudo mv /tmp/etcd.yaml /etc/kubernetes/manifests/

sudo mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/

sudo mv /tmp/kube-controller-manager.yaml /etc/kubernetes/manifests/

sudo mv /tmp/kube-scheduler.yaml /etc/kubernetes/manifests/



\# Wait for components to start

sleep 60



\# Check if components are running

kubectl get pods -n kube-system



\# Check if backup-test namespace exists

kubectl get namespaces | grep backup-test



\# Verify all resources in the namespace

kubectl get all -n backup-test



\# Check ConfigMap and Secret

kubectl get configmap,secret -n backup-test



\# Verify pod functionality

kubectl get pods -n backup-test -o wide



\# Save current state

kubectl get all -n backup-test > /tmp/post-restore-state.txt



\# Compare states

echo "=== Comparing States ==="

echo "Pre-failure resources:"

cat /tmp/pre-failure-state.txt



echo "Post-restore resources:"

cat /tmp/post-restore-state.txt



\# Verify specific resources

kubectl describe deployment nginx-deployment -n backup-test

kubectl get configmap test-config -n backup-test -o yaml



*Troubleshoot: If pods don't start after restore:*



\# Check kubelet logs

sudo journalctl -u kubelet -f



\# Restart kubelet if needed

sudo systemctl restart kubelet



\# Check pod events

kubectl describe pods -n kube-system



###### 6\. Test Application functionality and verify resource integrity



A. Test that the restored applications are fully functional:



\# Check pod logs

kubectl logs -n backup-test deployment/nginx-deployment



\# Test service connectivity

kubectl get svc -n backup-test



\# Port forward to test nginx

kubectl port-forward -n backup-test svc/nginx-service 8080:80 \&

PF\_PID=$!



\# Test connectivity (in another terminal or after a moment)

sleep 5

curl http://localhost:8080



\# Stop port forwarding

kill $PF\_PID



B. Ensure all resource configurations are intact:



\# Check deployment configuration

kubectl get deployment nginx-deployment -n backup-test -o yaml



\# Verify ConfigMap data

kubectl get configmap test-config -n backup-test -o yaml



\# Check Secret (base64 encoded)

kubectl get secret test-secret -n backup-test -o yaml



###### 7\. Production best practices



Create a script for regular backups



\# Verify backup integrity

etcdctl snapshot status $BACKUP\_FILE --write-out=table



\# Test restore in a separate environment before production use

