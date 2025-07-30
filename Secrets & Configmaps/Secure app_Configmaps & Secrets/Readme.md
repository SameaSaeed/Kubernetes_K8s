#### **ConfigMaps vs Secrets**



ConfigMaps are used for: • Non-sensitive configuration data • Application settings • Configuration files • Environment-specific values



Secrets are used for: • Sensitive information (passwords, tokens, keys) • TLS certificates • Docker registry credentials • API keys



##### **1. Configmap**



\#Create a ConfigMap

kubectl create configmap app-properties --from-file=app.properties



\#Create Pod manifest that uses the ConfigMap

kubectl get configmap app-properties -o yaml

kubectl apply -f pod-with-configmap.yaml



\#Check the environment variables inside the Pod

kubectl exec app-pod-env -- env | grep -E "(DATABASE|APP|LOG)"



##### **2. Secrets**



***#Create secrets*** 



1. ###### Create a secret with kubectl


kubectl create secret generic db-credentials \\
 --from-literal=username=admin \\

&nbsp;   --from-literal=password=supersecret123



###### 2\. Create a secret from yaml manifest

kubectl apply -f ~/secrets-lab/api-secret.yaml



###### 3\. Create a secret from files

echo -n 'admin' > username.txt

echo -n 'supersecret123' > password.txt

kubectl create secret generic file-credentials --from-file=username.txt --from-file=password.txt

rm username.txt password.txt



***#Create a Pod manifest that uses secrets***



###### 1\. Mount secrets as Volumes



\# Deploy the Pod

kubectl apply -f ~/secrets-lab/pod-with-secret-volume.yaml



\# Wait for Pod to be ready

kubectl wait --for=condition=Ready pod/secret-volume-pod --timeout=60s



\# Access the Pod and verify secret files

kubectl exec -it secret-volume-pod -- ls -la /etc/secrets



\# View the secret contents

kubectl exec -it secret-volume-pod -- cat /etc/secrets/username

kubectl exec -it secret-volume-pod -- cat /etc/secrets/password



###### 2\. Use secrets as environment variables



\# Deploy the Pod

kubectl apply -f ~/secrets-lab/pod-with-secret-env.yaml



\# Wait for Pod to be ready

kubectl wait --for=condition=Ready pod/secret-env-pod --timeout=60s



\# View specific environment variables

kubectl exec -it secret-env-pod -- env | grep -E "DB\_|API\_"

kubectl exec -it secret-env-pod -- printenv DB\_USERNAME

kubectl exec -it secret-env-pod -- printenv DB\_PASSWORD



##### **3. Mount Both ConfigMaps and Secrets into Pods as Files**



\#Apply pod-with-files manifest

kubectl apply -f pod-with-volumes.yaml

kubectl wait --for=condition=Ready pod/app-pod-volumes --timeout=60s



\#Apply the deployment

kubectl apply -f deployment-with-config.yaml

kubectl get pods -l app=web-app



##### **4. Verify mounted files**



\#View ConfigMap content:

kubectl exec app-pod-volumes -- ls -la /etc/config/

kubectl exec app-pod-volumes -- cat /etc/config/DATABASE\_HOST

kubectl exec app-pod-volumes -- cat /etc/config/APP\_ENV



\#Check the Secret files (note the restricted permissions):

kubectl exec app-pod-volumes -- ls -la /etc/secrets/



\#View Secret content:

kubectl exec app-pod-volumes -- cat /etc/secrets/username



\#Check the properties file:

kubectl exec app-pod-volumes -- ls -la /etc/properties/

kubectl exec app-pod-volumes -- cat /etc/properties/app.properties



\#Test configuration in one of the deployment pod

POD\_NAME=$(kubectl get pods -l app=web-app -o jsonpath='{.items\[0].metadata.name}')

kubectl exec $POD\_NAME -- env | grep -E "(DATABASE|APP|LOG|DB\_)"



##### **5. Update Configmaps \& secrets**



###### A. Configmaps



\#Update configmaps

kubectl patch configmap app-config --patch '{"data":{"LOG\_LEVEL":"debug","NEW\_FEATURE":"enabled"}}'



\#Verify the update:

kubectl describe configmap app-config



\#Check if mounted files are updated (may take a few moments):

kubectl exec app-pod-volumes -- cat /etc/config/LOG\_LEVEL

kubectl exec app-pod-volumes -- cat /etc/config/NEW\_FEATURE



###### B. Secrets



\#Update the Secret:

kubectl patch secret db-credentials --patch '{"data":{"api-key":"'$(echo -n 'new-api-key-123' | base64)'"}}'



\#Verify the Secret update:

kubectl describe secret db-credentials



##### **Security Considerations**

• Secrets are base64 encoded, not encrypted by default • Use RBAC to control access to Secrets • Consider using external secret management systems for production • Set appropriate file permissions when mounting Secrets • Avoid logging Secret values



##### **Performance Tips**

• ConfigMaps and Secrets have size limits (1MB) • Volume mounts are eventually consistent • Environment variables are set at container startup • Use subPath for mounting specific files

