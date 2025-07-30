In Kubernetes, StorageClass and Deployment serve distinct, yet related, purposes. A StorageClass defines the characteristics of storage offered to a cluster, like performance and availability, while a Deployment manages how applications are deployed and updated. StorageClasses are used for dynamic storage provisioning, and Deployments manage the desired state of application instances. 



###### 1\. Check existing StorageClasses:



kubectl get storageclass



View detailed information about default StorageClass:

kubectl describe storageclass



Check for existing PersistentVolumes:

kubectl get pv



Apply the StorageClass configuration:

kubectl apply -f custom-storageclass.yaml



Verify the StorageClass was created:

kubectl get storageclass fast-storage -o yaml



###### 2\. Create PV and PVC



Apply the PersistentVolume configuration:

kubectl apply -f mysql-pv.yaml



Verify the PV was created and check its status:

kubectl get pv mysql-pv

kubectl describe pv mysql-pv



Apply the PVC configuration:

kubectl apply -f mysql-pvc.yaml



Verify the PVC was created and bound to the PV:

kubectl get pvc mysql-pvc

kubectl describe pvc mysql-pvc



Check that the PV is now bound:

kubectl get pv mysql-pv



###### 3\. Deploy MySQL stateful app



Create the MySQL secret

kubectl create secret generic mysql-secret \\

&nbsp; --from-literal=mysql-root-password=MySecurePassword123 \\

&nbsp; --from-literal=mysql-database=testdb \\

&nbsp; --from-literal=mysql-user=testuser \\

&nbsp; --from-literal=mysql-password=TestUserPassword123



Verify the secret was created:

kubectl get secret mysql-secret

kubectl describe secret mysql-secret



Deploy MySQL:

kubectl apply -f mysql-deployment.yaml



Check the deployment status:

kubectl get deployment mysql-deployment

kubectl get pods -l app=MySQL



Wait for the pod to be ready (this may take a few minutes):

kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s



Apply the service configuration:

kubectl apply -f mysql-service.yaml



Verify the service was created:

kubectl get service mysql-service

kubectl describe service mysql-service



###### 4\. Verify Data Persistence



a. Get the MySQL pod name:

MYSQL\_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items\[0].metadata.name}')

echo "MySQL Pod: $MYSQL\_POD"



b. Connect to MySQL and create test data:

kubectl exec -it $MYSQL\_POD -- mysql -u root -pMySecurePassword123 -e "

CREATE DATABASE IF NOT EXISTS testdb;

USE testdb;

CREATE TABLE IF NOT EXISTS users (

&nbsp;   id INT AUTO\_INCREMENT PRIMARY KEY,

&nbsp;   name VARCHAR(50) NOT NULL,

&nbsp;   email VARCHAR(100) NOT NULL,

&nbsp;   created\_at TIMESTAMP DEFAULT CURRENT\_TIMESTAMP

);

INSERT INTO users (name, email) VALUES 

&nbsp;   ('John Doe', 'john@example.com'),

&nbsp;   ('Jane Smith', 'jane@example.com'),

&nbsp;   ('Bob Johnson', 'bob@example.com');

SELECT \* FROM users;



c. Verify the data was inserted:

kubectl exec -it $MYSQL\_POD -- mysql -u root -pMySecurePassword123 -e "

USE testdb;

SELECT COUNT(\*) as 'Total Users' FROM users;



d. Delete the MySQL pod:

kubectl delete pod $MYSQL\_POD



e. Wait for the new pod to be ready:

kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s



f. Get the new pod name:

NEW\_MYSQL\_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items\[0].metadata.name}')

echo "New MySQL Pod: $NEW\_MYSQL\_POD"



g. Verify that our data still exists:

kubectl exec -it $NEW\_MYSQL\_POD -- mysql -u root -pMySecurePassword123 -e "

USE testdb;

SELECT \* FROM users;

SELECT COUNT(\*) as 'Total Users' FROM users;



h. Scale down the deployment to 0 replicas:

kubectl scale deployment mysql-deployment --replicas=0



I. Verify no pods are running:

kubectl get pods -l app=mysql



j. Scale back up to 1 replica:

kubectl scale deployment mysql-deployment --replicas=1



k. Wait for the pod to be ready:

kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s



l. Verify data persistence again:

SCALED\_MYSQL\_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items\[0].metadata.name}')

kubectl exec -it $SCALED\_MYSQL\_POD -- mysql -u root -pMySecurePassword123 -e "

USE testdb;

SELECT \* FROM users;



5\. Advanced



Check the actual disk usage on the host:

sudo du -sh /var/lib/mysql-data

sudo ls -la /var/lib/mysql-data



Create a backup directory:

sudo mkdir -p /backup/MySQL



Create a database dump:

kubectl exec $SCALED\_MYSQL\_POD -- mysqldump -u root -pMySecurePassword123 --all-databases > /tmp/mysql-backup.sql



Copy the backup to our backup directory:

sudo cp /tmp/mysql-backup.sql /backup/mysql/mysql-backup-$(date +%Y%m%d-%H%M%S).sql



Verify the backup was created:

sudo ls -la /backup/mysql/



Test the dynamic PVC

kubectl apply -f dynamic-pvc.yaml

kubectl get pvc dynamic-pvc

kubectl get pv



6\. Troubleshoot: MySQL connection issues



Check pod logs:

kubectl logs -l app=MySQL



Verify service endpoints:

kubectl get endpoints mysql-service



Test connectivity:

kubectl run mysql-client --image=mysql:8.0 -it --rm --restart=Never -- mysql -h mysql-service -u root -pMySecurePassword123

