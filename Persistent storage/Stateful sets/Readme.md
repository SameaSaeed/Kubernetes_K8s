1. ##### Deploy a StatefulSet for a Sample Database Application



\# Create the headless service configuration file

kubectl apply -f mysql-headless-service.yaml



\# Verify the service was created

kubectl get services



\# Create a storage class for our persistent volumes

kubectl apply -f mysql-storage-class.yaml



\# Verify the storage class

kubectl get storageclass



\# Create the StatefulSet configuration

kubectl apply -f mysql-statefulset.yaml



\# Watch the pods being created in order

kubectl get pods -w



\# Check the automatically created PVCs

kubectl get pvc



\# Get detailed information about the PVCs

kubectl describe pvc



\# Check the persistent volumes

kubectl get pv



##### 2\. Test Persistence



\# Connect to the first MySQL pod

kubectl exec -it mysql-statefulset-0 -- mysql -u root -prootpassword123



\# Inside the MySQL shell, run these commands:

\# CREATE TABLE test\_table (id INT PRIMARY KEY, name VARCHAR(50));

\# INSERT INTO test\_table VALUES (1, 'StatefulSet Test Data');

\# SELECT \* FROM test\_table;

\# EXIT;



Alternative method using a single command:

\# Create test data using a single command

kubectl exec -it mysql-statefulset-0 -- mysql -u root -prootpassword123 -e "

CREATE DATABASE IF NOT EXISTS testdb;

USE testdb;

CREATE TABLE IF NOT EXISTS test\_table (id INT PRIMARY KEY, name VARCHAR(50));

INSERT INTO test\_table VALUES (1, 'StatefulSet Test Data');

SELECT \* FROM test\_table;

"



\# Delete the pod to simulate a failure

kubectl delete pod mysql-statefulset-0



\# Watch the pod being recreated

kubectl get pods -w

After the pod is recreated, verify the data still exists:



\# Check if our test data persisted

kubectl exec -it mysql-statefulset-0 -- mysql -u root -prootpassword123 -e "

USE testdb;

SELECT \* FROM test\_table;

"



##### 3\. Scale the StatefulSet and Observe Its Behavior



\# Scale the StatefulSet from 3 to 5 replicas

kubectl scale statefulset mysql-statefulset --replicas=5



\# Watch the scaling process

kubectl get pods -w



\# Check the new PVCs created during scaling

kubectl get pvc



\# Verify all pods are running

kubectl get pods



\# Scale down from 5 to 2 replicas

kubectl scale statefulset mysql-statefulset --replicas=2



\# Watch the scaling down process

kubectl get pods -w



\# Check that PVCs from deleted pods still exist

kubectl get pvc



\# This shows StatefulSet's data safety feature

\# PVCs are retained even when pods are deleted



\# Scale back up to 4 replicas

kubectl scale statefulset mysql-statefulset --replicas=4



\# Watch pods being recreated

kubectl get pods -w



\# Verify that the recreated pod reattaches to its original PVC

kubectl get pvc



##### 5\. Advanced StatefulSet Operations



\# Update the StatefulSet with new resource limits

kubectl patch statefulset mysql-statefulset -p='{"spec":{"template":{"spec":{"containers":\[{"name":"mysql","resources":{"limits":{"memory":"1Gi","cpu":"1000m"}}}]}}}}'



\# Check the rollout status

kubectl rollout status statefulset/mysql-statefulset



\# Verify the update

kubectl describe statefulset mysql-statefulset



\# Check the DNS names of StatefulSet pods

kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup mysql-statefulset-0.mysql-headless.statefulset-lab.svc.cluster.local



\# Test connectivity to specific pods

kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup mysql-statefulset-1.mysql-headless.statefulset-lab.svc.cluster.local



\# Create a regular service for external access to the StatefulSet

kubectl apply -f mysql-service.yaml



\# Verify the service

kubectl get services



##### 6\. Monitoring



\# Get detailed StatefulSet information

kubectl describe statefulset mysql-statefulset



\# Check StatefulSet events

kubectl get events --sort-by=.metadata.creationTimestamp



\# Monitor pod logs

kubectl logs mysql-statefulset-0 --tail=20



##### 7\. Troubleshooting



\# Check pod status and ready conditions

kubectl get pods -o wide



\# Describe a specific pod for troubleshooting

kubectl describe pod mysql-statefulset-0



\# Check PVC binding status

kubectl get pvc -o wide



\# Verify storage class

kubectl describe storageclass mysql-storage



\# Pods Not Starting in Order



Verify headless service exists

kubectl get service mysql-headless



Check service selector matches StatefulSet labels

kubectl describe service mysql-headless

##### 

\# Data Not Persisting



Check PVC mounting

kubectl describe pod mysql-statefulset-0



Verify volume mounts

kubectl exec mysql-statefulset-0 -- df -h



##### 8\. Resource Management



Controlled Cleanup

\# Scale down to 0 replicas first

kubectl scale statefulset mysql-statefulset --replicas=0



\# Wait for all pods to terminate

kubectl get pods



\# Delete the StatefulSet

kubectl delete statefulset mysql-statefulset



\# Delete services

kubectl delete service mysql-headless mysql-service



\# Note: PVCs are still retained for data safety

kubectl get pvc

##### 

##### 9\. StatefulSet vs Deployment



Feature			StatefulSet			Deployment

Pod Names		Predictable (app-0, app-1)	Random

Scaling	Ordered 	sequential			Parallel

Storage	Persistent 	per pod				Shared or ephemeral

Network Identity	Stable DNS names		Load-balanced

Use Cases		Databases, distributed systems	Stateless applications



