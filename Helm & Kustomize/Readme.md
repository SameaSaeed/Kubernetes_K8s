#### **Helm**

##### 

##### 1\. Setup



\# Download and install Helm

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash



\# Verify Helm installation

helm version



\# Add the official Helm stable repository

helm repo add stable https://charts.helm.sh/stable



\# Add Bitnami repository (popular for production-ready charts)

helm repo add bitnami https://charts.bitnami.com/bitnami



\# Update repository information

helm repo update



\# List available repositories

helm repo list



\# Search for nginx charts

helm search repo nginx



\# Search for database charts

helm search repo mysql



\# Get detailed information about a specific chart

helm show chart bitnami/nginx

helm show values bitnami/nginx



##### 2\. Deploy Applications Using Helm Charts



\# Create a namespace for our applications

kubectl create namespace helm-demo



\# Install NGINX using Helm

helm install my-nginx bitnami/nginx --namespace helm-demo



\# Check the deployment status

helm status my-nginx --namespace helm-demo



\# List all Helm releases

helm list --namespace helm-demo



\# Update Helm release (If so)

helm upgrade custom-nginx bitnami/nginx \\

  --namespace helm-demo \\

  --set replicaCount=2 \\

  --set service.type=ClusterIP



\# Check Helm release status (If so)

helm status custom-nginx --namespace helm-demo



\# Check the created Kubernetes resources

kubectl get all -n helm-demo



##### 3a. Customize already existing deployments (with values)



\# Create a custom values file

helm install custom-nginx bitnami/nginx \\

  --namespace helm-demo \\

  --values custom-nginx-values.yaml



\# Verify the deployment

kubectl get pods -n helm-demo

kubectl get services -n helm-demo



##### 3b. Create a Custom Helm Chart



mkdir my-webapp \&\& cd my-webapp



\# Create a new Helm chart

helm create my-webapp



\# Explore the chart structure

ls -la my-webapp/

tree my-webapp/



\# Edit the values.yaml file



\# Validate the chart

helm lint my-webapp



\# Test the chart rendering

helm template my-webapp ./my-webapp --namespace helm-demo



\# Install the custom chart

helm install my-custom-app ./my-webapp --namespace helm-demo



\# Verify deployment

kubectl get all -n helm-demo -l app.kubernetes.io/name=my-webapp



##### 4\. Upgrade and Rollback Helm Releases



\# Upgrade the release with different replica count

helm upgrade custom-nginx bitnami/nginx \\

  --namespace helm-demo \\

  --set replicaCount=5



\# Check the upgrade

kubectl get pods -n helm-demo



\# View release history

helm history custom-nginx --namespace helm-demo



\# Rollback to previous version

helm rollback custom-nginx 1 --namespace helm-demo



\# Verify rollback

kubectl get pods -n helm-demo





#### **Kustomize**



1. ##### Install



\# Check if kustomize is available in kubectl

kubectl kustomize --help



\# Install standalone Kustomize

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install\_kustomize.sh" | bash



\# Move to PATH

sudo mv kustomize /usr/local/bin/



\# Verify installation

kustomize version

##### 

##### 2\. Create Base Kustomize Configuration



\# Create directory structure for Kustomize

mkdir -p kustomize-demo/{base,overlays/{development,staging,production}}



\# Create base deployment



\# Create base service



\# Create base kustomization file



\# Check Kustomize deployment status

kubectl rollout status deployment/webapp -n development





#### **Environment-Specific Overlays**



1. ##### Create Overlays



A. Create development overlay



mkdir -p kustomize-demo/overlays/development \&\& cd kustomize-demo/overlays/development



\# Create Kustomization

kubectl apply -f kustomization.yaml



\# Create development-specific patches

kubectl apply -f deployment-patch.yaml



B. Create staging overlay



mkdir -p kustomize-demo/overlays/staging \&\& cd kustomize-demo/overlays/staging



\# Create Kustomization

kubectl apply -f kustomization.yaml



\# Create development-specific patches

kubectl apply -f deployment-patch.yaml



\# Create services-specific patches

kubectl apply -f service-patch.yaml



C. Create production overlay



mkdir -p kustomize-demo/overlays/production \&\& cd kustomize-demo/overlays/production



\# Create Kustomization

kubectl apply -f kustomization.yaml



\# Create development-specific patches

kubectl apply -f deployment-patch.yaml



##### 2\. Deploy Using Kustomize



\# Create namespaces

kubectl create namespace development

kubectl create namespace staging

kubectl create namespace production



\# Deploy to development

kubectl apply -k kustomize-demo/overlays/development/



\# Deploy to staging

kubectl apply -k kustomize-demo/overlays/staging/



\# Deploy to production

kubectl apply -k kustomize-demo/overlays/production/



\# Verify deployments

kubectl get all -n development

kubectl get all -n staging

kubectl get all -n production



\# Check replica counts

echo "Development replicas:"

kubectl get deployment webapp -n development -o jsonpath='{.spec.replicas}'

echo



echo "Staging replicas:"

kubectl get deployment webapp -n staging -o jsonpath='{.spec.replicas}'

echo



echo "Production replicas:"

kubectl get deployment webapp -n production -o jsonpath='{.spec.replicas}'

echo



\# Check environment variables

kubectl exec -n development deployment/webapp -- env | grep ENVIRONMENT

kubectl exec -n staging deployment/webapp -- env | grep ENVIRONMENT

kubectl exec -n production deployment/webapp -- env | grep ENVIRONMENT



\# Check resource allocations

kubectl describe deployment webapp -n development | grep -A 10 "Limits\\|Requests"

kubectl describe deployment webapp -n production | grep -A 10 "Limits\\|Requests"



#### **Compare Helm and Kustomize Approaches**



**A. Kustomize**



\# Generate YAML output from Kustomize overlays

echo "=== Development Environment ==="

kubectl kustomize kustomize-demo/overlays/development/



echo "=== Staging Environment ==="

kubectl kustomize kustomize-demo/overlays/staging/



echo "=== Production Environment ==="

kubectl kustomize kustomize-demo/overlays/production/



**B. Helm**



\# Generate Helm template output with different values

echo "=== Helm Development Values ==="

helm template my-webapp ./my-webapp --set replicaCount=1,image.tag=1.21-alpine



echo "=== Helm Production Values ==="

helm template my-webapp ./my-webapp --set replicaCount=5,image.tag=1.21



**C. Comparison**



cat deployment-comparison.md



#### **Monitor**



\# View logs

kubectl logs -l app=webapp -n development --tail=10

kubectl logs -l app.kubernetes.io/name=nginx -n helm-demo --tail=10



\# Describe resources for troubleshooting

kubectl describe deployment webapp -n development

kubectl describe service webapp-service -n development

#### 

#### **Troubleshoot**



*Common Helm Issues:*

• Chart not found: Ensure repositories are added and updated with helm repo update • Release already exists: Use helm upgrade instead of helm install or choose a different release name • Permission denied: Check RBAC permissions and namespace access • Values not applied: Verify YAML syntax in values files



*Common Kustomize Issues:*

• Resource not found: Check file paths in kustomization.yaml • Patch not applying: Ensure patch targets match exactly with base resources • Namespace issues: Verify namespace exists before applying configurations • YAML syntax errors: Validate YAML files before applying



*General Debugging Commands:*

\# Check cluster resources

kubectl get events --sort-by=.metadata.creationTimestamp



\# Describe problematic resources

kubectl describe pod <pod-name> -n <namespace>



\# Check logs

kubectl logs <pod-name> -n <namespace> --previous



\# Validate configurations

helm lint <chart-directory>

kubectl kustomize <overlay-directory> --dry-run

