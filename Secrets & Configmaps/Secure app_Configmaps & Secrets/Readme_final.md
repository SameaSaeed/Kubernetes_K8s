#### **Secure application configuration**



##### A. Configmaps



1\. Create a ConfigMap with literal values

kubectl create configmap app-config \\

&nbsp; --from-literal=database\_host=mysql-service \\

&nbsp; --from-literal=database\_port=3306 \\

&nbsp; --from-literal=app\_mode=production \\

&nbsp; --from-literal=log\_level=info \\

&nbsp; --from-literal=max\_connections=100



2\. Create ConfigMap from file

kubectl create configmap app-properties --from-file=app.properties



\# Verify the file-based ConfigMap

kubectl describe configmap app-properties



3\.  Create a ConfigMap Using YAML Manifest

kubectl apply -f configmap-manifest.yaml



\# Verify all ConfigMaps

kubectl get configmaps



##### B. Secrets



1. Create a Secret with literal values



kubectl create secret generic app-secrets \\

&nbsp; --from-literal=database\_password=MySecurePassword123 \\

&nbsp; --from-literal=api\_key=sk-1234567890abcdef \\

&nbsp; --from-literal=jwt\_secret=super-secret-jwt-key-2024 \\

&nbsp; --from-literal=redis\_password=RedisPass456

Verify the Secret was created:



\# List all Secrets

kubectl get secrets



\# View Secret details (note that values are not shown)

kubectl describe secret app-secrets



\# View Secret in YAML format (values are base64 encoded)

kubectl get secret app-secrets -o yaml



2\. Create a Secret from Files



\# Create sensitive configuration files

echo -n "MySecurePassword123" > db-password.txt

echo -n "sk-1234567890abcdef" > api-key.txt



\# Create a certificate file (simulated)

tls.crt



\# Create Secret from files

kubectl create secret generic file-secrets \\

&nbsp; --from-file=database-password=db-password.txt \\

&nbsp; --from-file=api-key=api-key.txt \\

&nbsp; --from-file=tls.crt=tls.crt



\# Clean up sensitive files

rm db-password.txt api-key.txt



3\. Create a Secret Using YAML Manifest



\# Encode values to base64

echo -n "admin123" | base64  # Output: YWRtaW4xMjM=

echo -n "secret-api-key-xyz" | base64  # Output: c2VjcmV0LWFwaS1rZXkteHl6



\# Apply the Secret

kubectl apply -f secret-manifest.yaml



\# Verify all Secrets

kubectl get secrets



##### C. Create an Application Pod with ConfigMap and Secret



\# Apply the deployment

kubectl apply -f app-deployment.yaml



\# Check deployment status

kubectl get deployments

kubectl get pods



\# Wait for pod to be ready

kubectl wait --for=condition=ready pod -l app=secure-app --timeout=60s



\# Apply the debug pod

kubectl apply -f debug-pod.yaml



\# Wait for pod to be ready

kubectl wait --for=condition=ready pod debug-pod --timeout=60s



##### D. Verify Application Access to ConfigMap and Secret



a. Configmap



\# Get pod name

POD\_NAME=$(kubectl get pods -l app=secure-app -o jsonpath='{.items\[0].metadata.name}')



\# Check environment variables from ConfigMap

kubectl exec $POD\_NAME -- env | grep -E "(DATABASE\_HOST|DATABASE\_PORT|APP\_MODE)"



\# Check mounted ConfigMap files

kubectl exec $POD\_NAME -- ls -la /etc/config/

kubectl exec $POD\_NAME -- cat /etc/config/nginx.conf

kubectl exec $POD\_NAME -- cat /etc/config/app-config.json



\# Check properties file

kubectl exec $POD\_NAME -- ls -la /etc/app/

kubectl exec $POD\_NAME -- cat /etc/app/app.properties



b. Secret



\# Check environment variables from Secret (be careful with sensitive data)

kubectl exec $POD\_NAME -- sh -c 'echo "API\_KEY length: ${#API\_KEY}"'

kubectl exec $POD\_NAME -- sh -c 'echo "DATABASE\_PASSWORD is set: $(\[ -n "$DATABASE\_PASSWORD" ] \&\& echo "YES" || echo "NO")"'



\# Check mounted Secret files

kubectl exec $POD\_NAME -- ls -la /etc/secrets/

kubectl exec $POD\_NAME -- wc -c /etc/secrets/api-key

kubectl exec $POD\_NAME -- file /etc/secrets/tls.crt



Use the debug pod for more detailed testing:



\# Execute interactive shell in debug pod

kubectl exec -it debug-pod -- sh



\# Inside the pod, run these commands:

Once inside the debug pod, execute these commands:



\# Check all environment variables

env | sort



\# Check ConfigMap environment variables

env | grep -E "(database\_|app\_|log\_|max\_)"



\# Check Secret environment variables

echo "API Key length: ${#SECRET\_API\_KEY}"

echo "DB Password is set: $(\[ -n "$SECRET\_DB\_PASSWORD" ] \&\& echo "YES" || echo "NO")"



\# Check mounted ConfigMap files

ls -la /config/

cat /config/app-config.json | head -10



\# Check mounted Secret files

ls -la /secrets/

wc -c /secrets/\*



\# Exit the pod

exit



##### E. Verify Security and Permissions



\# Check Secret permissions in the pod

kubectl exec $POD\_NAME -- ls -la /etc/secrets/



\# Verify that Secrets are not visible in pod description

kubectl describe pod $POD\_NAME | grep -A 10 -B 10 -i secret



\# Check ConfigMap visibility (should be visible)

kubectl describe pod $POD\_NAME | grep -A 5 -B 5 -i configmap



\# Verify base64 encoding of Secrets

kubectl get secret app-secrets -o jsonpath='{.data.api\_key}' | base64 -d

echo  # Add newline



##### F. Advanced Configuration Scenarios



###### a. Update ConfigMap and Observe Changes



\# Update the ConfigMap

kubectl patch configmap app-config --patch '{"data":{"log\_level":"debug","max\_connections":"200"}}'



\# Check the updated ConfigMap

kubectl get configmap app-config -o yaml



\# Note: Environment variables won't update automatically

\# But mounted volumes will update (may take up to 1 minute)



\# Check if mounted files are updated

kubectl exec $POD\_NAME -- cat /etc/config/app-config.json



###### b. Create a Rolling Update with New Configuration



\# Create a new ConfigMap version

kubectl create configmap app-config-v2 \\

&nbsp; --from-literal=database\_host=mysql-service-v2 \\

&nbsp; --from-literal=database\_port=3306 \\

&nbsp; --from-literal=app\_mode=staging \\

&nbsp; --from-literal=log\_level=debug \\

&nbsp; --from-literal=max\_connections=150 \\

&nbsp; --from-literal=app\_version=2.0.0



\# Update deployment to use new ConfigMap

kubectl patch deployment secure-app --patch '

spec:

&nbsp; template:

&nbsp;   spec:

&nbsp;     containers:

&nbsp;     - name: app-container

&nbsp;       env:

&nbsp;       - name: DATABASE\_HOST

&nbsp;         valueFrom:

&nbsp;           configMapKeyRef:

&nbsp;             name: app-config-v2

&nbsp;             key: database\_host

&nbsp;       - name: APP\_VERSION

&nbsp;         valueFrom:

&nbsp;           configMapKeyRef:

&nbsp;             name: app-config-v2

&nbsp;             key: app\_version'



\# Watch the rolling update

kubectl rollout status deployment/secure-app



\# Verify new configuration

NEW\_POD\_NAME=$(kubectl get pods -l app=secure-app -o jsonpath='{.items\[0].metadata.name}')

kubectl exec $NEW\_POD\_NAME -- env | grep -E "(DATABASE\_HOST|APP\_VERSION)"



###### c. Configuration Validation



\# Apply the validated app

kubectl apply -f validated-app.yaml



\# Check init container logs

kubectl logs validated-app -c config-validator



\# Check if main container started successfully

kubectl get pod validated-app

kubectl logs validated-app -c main-app



##### G. Troubleshooting

&nbsp;

Issue 1: Pod fails to start with Secret reference error

\# Solution: Check if Secret exists and has correct key names

kubectl get secrets

kubectl describe secret <secret-name>



Issue 2: ConfigMap changes not reflected in pod

\# Solution: ConfigMap environment variables require pod restart

kubectl rollout restart deployment/<deployment-name>



Issue 3: Permission denied accessing mounted secrets

\# Solution: Check file permissions and security context

kubectl exec <pod-name> -- ls -la /path/to/secrets



Issue 4: Base64 encoding issues

\# Solution: Ensure proper encoding without newlines

echo -n "your-secret" | base64

