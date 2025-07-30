

##### A. Pod Security Standards:



1\. Check if Pod Security Admission is enabled in your cluster:

kubectl api-versions | grep admissionregistration



2\. Apply Pod Security Standards labels

\#Create a restricted namespace

kubectl create namespace secure-apps



\#Create standarad

&nbsp; kubectl label namespace secure-apps \\

&nbsp; pod-security.kubernetes.io/enforce=restricted \\

&nbsp; pod-security.kubernetes.io/audit=restricted \\

&nbsp; pod-security.kubernetes.io/warn=restricted



\#Apply to pods

kubectl apply -f insecure-pod.yaml

kubectl apply -f secure-pod.yaml



##### B. Network Policies



***1. Deploy apps***



\# Create namespaces

kubectl create namespace frontend

kubectl create namespace backend

kubectl create namespace database



\# Label namespaces for easy identification

kubectl label namespace frontend tier=frontend

kubectl label namespace backend tier=backend

kubectl label namespace database tier=database



\#Deploy apps

kubectl apply -f frontend-app.yaml

kubectl apply -f backend-app.yaml

kubectl apply -f database-app.yaml



***2. Apply \& test Network policies***



\# Check if your CNI supports Network Policies

kubectl get pods -n kube-system | grep -E "(calico|cilium|weave)"



\# Apply network policy

kubectl apply -f database-network-policy.yaml

kubectl apply -f backend-network-policy.yaml



\# This should fail - frontend cannot directly access database

kubectl exec -n frontend $FRONTEND\_POD -- nc -zv database-service.database.svc.cluster.local 5432



\# This should work - frontend can access backend

kubectl exec -n frontend $FRONTEND\_POD -- wget -qO- --timeout=2 http://backend-service.backend.svc.cluster.local



\# Test from backend to database (should work)

BACKEND\_POD=$(kubectl get pods -n backend -o jsonpath='{.items\[0].metadata.name}')

kubectl exec -n backend $BACKEND\_POD -- nc -zv database-service.database.svc.cluster.local 5432



##### C. Image Scanning with Trivy



1. ###### **Install Trivy**



\# Download and install Trivy

curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.48.0



\# Verify installation

trivy version



\# Trivy fails to scan the image



1. Update Trivy database

trivy image --download-db-only



2\. Check internet connectivity

curl -I https://github.com



3\. Scan with debug output

trivy image --debug nginx:latest



###### **2a. Secure Image build process**

\# Create file: Dockerfile.secure



###### **2b. Scan a container image for vulnerabilities**

\# Scan nginx image

trivy image nginx:latest



\# Scan with specific severity levels

trivy image --severity HIGH,CRITICAL nginx:latest



\# Generate JSON report

trivy image --format json --output nginx-scan.json nginx:latest



###### **3. Scan images in Kubernetes**

chmod +x scan-cluster-images.sh

./scan-cluster-images.sh



###### **4. Image Scanning in CI/CD**



##### D. RBAC \& Resource Quota

kubectl apply -f rbac-config.yaml

kubectl apply -f resource-quota.yaml

##### 

