#### **1. Create Lab Namespace**



\# Create a namespace for the lab

kubectl create namespace storage-lab



\# Set the namespace as default for this session

kubectl config set-context --current --namespace=storage-lab



\# Verify namespace creation

kubectl get namespaces



#### **2. Create Persistent Volume** 



\# Create a persistent volume

nano persistent-volume.yaml

Copy and paste the respective content



\#Apply the PersistentVolume:

kubectl apply -f persistent-volume.yaml



\# Verify PV creation

kubectl get pv



\# Get detailed information about the PV

kubectl describe pv lab-pv



#### **3. Create Persistent Volume Claim**



\#Apply the PersistentVolume-claim:

kubectl apply -f persistent-volume-claim.yaml



\# Create the PVC

kubectl apply -f persistent-volume-claim.yaml



\# Check PVC status

kubectl get pvc



\# Verify PV is now bound to PVC

kubectl get pv



\# Get detailed PVC information

kubectl describe pvc lab-pvc



#### **4. Deploy the application with persistent storage**



kubectl apply -f storage-app-deployment.yaml



\# Check deployment status

kubectl get deployments



\# Wait for the pod to be running

kubectl wait --for=condition=Ready pod -l app=storage-app --timeout=60s



\# Get the pod name

POD\_NAME=$(kubectl get pods -l app=storage-app -o jsonpath='{.items\[0].metadata.name}')



\# Check if data is being written

kubectl exec $POD\_NAME -- ls -la /data



\# View the content of the log file

kubectl exec $POD\_NAME -- cat /data/timestamps.log



\# Monitor real-time data writing (press Ctrl+C to stop)

kubectl exec $POD\_NAME -- tail -f /data/timestamps.log



#### **5. Create a service for application access**



\# Apply the service

kubectl apply -f storage-app-service.yaml



\# Verify service creation

kubectl get services



#### **6. Verify data persistence**



1. **Delete and Recreate Application:**



\#The data we have

kubectl exec $POD\_NAME -- wc -l /data/timestamps.log



\# Note the current timestamp count

INITIAL\_COUNT=$(kubectl exec $POD\_NAME -- wc -l /data/timestamps.log | awk '{print $1}')

echo "Initial line count: $INITIAL\_COUNT"



\# Delete the deployment (this will delete the pod)

kubectl delete deployment storage-app



\# Verify the pod is deleted

kubectl get pods



\# Wait a moment to ensure complete deletion

sleep 10



**2. Recreate Application and Verify Data:**



\# Recreate the deployment

kubectl apply -f storage-app-deployment.yaml



\# Wait for the new pod to be ready

kubectl wait --for=condition=Ready pod -l app=storage-app --timeout=60s



\# Get new pod name

NEW\_POD\_NAME=$(kubectl get pods -l app=storage-app -o jsonpath='{.items\[0].metadata.name}')



\# Check if our data still exists

kubectl exec $NEW\_POD\_NAME -- ls -la /data



\# Verify the log file still contains our previous data

kubectl exec $NEW\_POD\_NAME -- head -5 /data/timestamps.log



\# Check current line count

CURRENT\_COUNT=$(kubectl exec $NEW\_POD\_NAME -- wc -l /data/timestamps.log | awk '{print $1}')

echo "Current line count: $CURRENT\_COUNT"



\# The count should be equal to or greater than the initial count

if \[ $CURRENT\_COUNT -ge $INITIAL\_COUNT ]; then

&nbsp;   echo "SUCCESS: Data persisted across pod deletion and recreation!"

else

&nbsp;   echo "WARNING: Some data may have been lost"

fi



**3. Advanced Persistence Testing:**



**a. Verification inside a pod**

\# Create a test file with specific content

kubectl exec $NEW\_POD\_NAME -- sh -c 'echo "Persistence Test - $(date)" > /data/test-file.txt'



\# Add some structured data

kubectl exec $NEW\_POD\_NAME -- sh -c 'echo "Lab: Kubernetes Persistent Storage" >> /data/test-file.txt'

kubectl exec $NEW\_POD\_NAME -- sh -c 'echo "Student: $(whoami)" >> /data/test-file.txt'

kubectl exec $NEW\_POD\_NAME -- sh -c 'echo "Node: $(hostname)" >> /data/test-file.txt'



\# Verify file creation

kubectl exec $NEW\_POD\_NAME -- cat /data/test-file.txt



\# Scale deployment to 0 replicas (another way to delete pods)

kubectl scale deployment storage-app --replicas=0



\# Verify no pods are running

kubectl get pods



\# Scale back to 1 replica

kubectl scale deployment storage-app --replicas=1



\# Wait for the pod to be ready

kubectl wait --for=condition=Ready pod -l app=storage-app --timeout=60s



\# Get the newest pod name

FINAL\_POD\_NAME=$(kubectl get pods -l app=storage-app -o jsonpath='{.items\[0].metadata.name}')



\# Verify our test file still exists

kubectl exec $FINAL\_POD\_NAME -- cat /data/test-file.txt



echo "Final persistence test completed successfully!"



**b. Verification through script**



chmod +x final-verification.sh

./final-verification.sh



#### **7. Storage Management and Monitoring**



1. **Monitoring inside a pod**



\# Check storage usage inside the pod

kubectl exec $FINAL\_POD\_NAME -- df -h /data



\# Check PV and PVC status

kubectl get pv,pvc



\# Get detailed storage information

kubectl describe pv lab-pv

kubectl describe pvc lab-pvc



\# Check events related to storage

kubectl get events --field-selector involvedObject.kind=PersistentVolume

kubectl get events --field-selector involvedObject.kind=PersistentVolumeClaim



**2. Monitoring through a script**



\# Make the script executable

chmod +x monitor-storage.sh



\# Run the monitoring script

./monitor-storage.sh



#### **8. Troubleshooting**

#### &nbsp;

\# Check events to understand the problem

kubectl get events --field-selector involvedObject.name=large-pvc



\# PVC Stuck in Pending State

kubectl describe pvc <pvc-name>

kubectl get events --field-selector involvedObject.name=<pvc-name>



\# Pod cannot Mount Volume

kubectl describe pod <pod-name>

kubectl get events --field-selector involvedObject.name=<pod-name>



\# Data Not Persisting

kubectl get pv,pvc

kubectl describe pv <pv-name>

#### **9. Real-World Applications

Database Deployments: PostgreSQL, MySQL, MongoDB in Kubernetes
Content Management: WordPress, Drupal, and other CMS platforms
Data Analytics: Persistent storage for data processing pipelines
File Sharing: Network-attached storage solutions
Backup Systems: Implementing enterprise backup and recovery solutions



