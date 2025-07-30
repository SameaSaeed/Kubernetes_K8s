##### Application delivery with GitOps



###### **1. Setting up ArgoCD**



\# Start Minikube cluster

minikube start --driver=docker --memory=4096 --cpus=2



\# Ensure sufficient resources

minikube config set memory 4096

minikube config set cpus 2

minikube delete \&\& minikube start



\# Create argocd namespace

kubectl create namespace argocd



\# Install ArgoCD

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml



\# Wait for all pods to be ready (this may take 2-3 minutes)

kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd



\# Check ArgoCD pods status

kubectl get pods -n argocd



\# Port forward ArgoCD server (run this in background)

kubectl port-forward svc/argocd-server -n argocd 8080:443 \&



\# Get initial admin password

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d \&\& echo



\# Download ArgoCD CLI

curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64



\# Make it executable and move to PATH

sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd



\# Verify installation

argocd version --client



\# Login to ArgoCD (use the password from step 2.2)

argocd login localhost:8080 --username admin --password <your-password> --insecure



\# Verify login

argocd account get-user-info



###### **2. Create and commit application manifests (deployment, service, and namespace) to git**



\# Delete ArgoCD application

argocd app delete sample-app --cascade



\# Delete sample-app namespace

kubectl delete namespace sample-app



\# Delete ArgoCD namespace (optional)

kubectl delete namespace argocd



###### **3. Integrate ArgoCD with Git Repo**



\# Apply the ArgoCD application

kubectl apply -f argocd-app.yaml



\# List ArgoCD applications

argocd app list



\# Get detailed application information

argocd app get sample-app



\# Check application status

argocd app status sample-app



###### **4. Deploying apps through GitOps**



\# Sync the application

argocd app sync sample-app



\# Wait for sync to complete

argocd app wait sample-app --timeout 300



\# Check if namespace was created

kubectl get namespaces



\# Check pods in sample-app namespace

kubectl get pods -n sample-app



\# Check services

kubectl get services -n sample-app



\# Check deployment status

kubectl get deployments -n sample-app



\# Port forward to test the application

kubectl port-forward -n sample-app svc/sample-app-service 8081:80 \&



\# Test the application (in a new terminal or after a few seconds)

curl http://localhost:8081



\# Stop port forwarding

pkill -f "kubectl port-forward"



###### **5. Updating apps through Git commits**



\# Update deployment to use 3 replicas

sed -i 's/replicas: 2/replicas: 3/' apps/sample-app/deployment.yaml



\# Verify the change

grep "replicas:" apps/sample-app/deployment.yaml



\# Update nginx image version

sed -i 's/nginx:1.21/nginx:1.22/' apps/sample-app/deployment.yaml



\# Verify the change

grep "image:" apps/sample-app/deployment.yaml



\# Add changes to Git

git add apps/sample-app/deployment.yaml



\# Commit changes

git commit -m "Update: Increase replicas to 3 and upgrade nginx to 1.22"



\# View commit history

git log --oneline -n 3



\# Monitor the sync process

argocd app sync sample-app



\# Wait for sync completion

argocd app wait sample-app



###### **6. Monitor ArgoCD sync**



\# Check application status

argocd app get sample-app



\# View detailed information

kubectl get events -n sample-app --sort-by='.lastTimestamp'



\# Watch the sync process (press Ctrl+C to stop)

watch -n 2 'argocd app get sample-app | grep -E "(Health|Sync)"'



\# Check if replicas increased to 3

kubectl get pods -n sample-app



\# Check deployment details

kubectl describe deployment sample-app -n sample-app | grep -E "(Replicas|Image)"



\# Verify image version

kubectl get deployment sample-app -n sample-app -o jsonpath='{.spec.template.spec.containers\[0].image}'

echo



\# View application history

argocd app history sample-app



\# Get detailed sync information

argocd app get sample-app --show-operation



###### **7. Observability:**



\# Get application resource usage

kubectl top pods -n sample-app



\# View application logs

kubectl logs -n sample-app -l app=sample-app --tail=20



\# Check application health

argocd app get sample-app --show-params

