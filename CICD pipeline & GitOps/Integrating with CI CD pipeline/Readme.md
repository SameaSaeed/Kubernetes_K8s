##### **Setting K8s application**



###### \#Set minikube cluster

minikube start --driver=docker --memory=4096 --cpus=2

minikube addons enable ingress

minikube addons enable metrics-server

eval $(minikube docker-env)



###### \#Build and test locally

docker build -t cicd-app:v1.0.0 .

docker run -d -p 3000:3000 --name test-app cicd-app:v1.0.0

curl http://localhost:3000

curl http://localhost:3000/health

docker stop test-app

docker rm test-app



###### \#Deploy to Kubernetes

sed -i 's|image: cicd-app:latest|image: cicd-app:v1.0.0|g' k8s-manifests/deployment.yaml

sed -i 's|imagePullPolicy: Always|imagePullPolicy: Never|g' k8s-manifests/deployment.yaml

kubectl apply -f k8s-manifests/

kubectl rollout status deployment/cicd-app



###### \#Test the deployed application

minikube service cicd-app-service --url

SERVICE\_URL=$(minikube service cicd-app-service --url)

curl $SERVICE\_URL

curl $SERVICE\_URL/health



###### \#Test CI/CD Pipeline



\#Make a change to the application:

sed -i 's/version: process.env.APP\_VERSION || '\\''1.0.0'\\''/version: process.env.APP\_VERSION || '\\''1.1.0'\\''/g' app.js



\#Commit and push the change:

git add app.js

git commit -m "Update application version to 1.1.0"

git push origin main



\#Verify the new version is running:

kubectl get pods

SERVICE\_URL=$(minikube service cicd-app-service --url)

curl $SERVICE\_URL

###### 

###### \#Test Rollback



***#Commit and push the broken version:***

git add app.js

git commit -m "Deploy broken version 2.0.0 (for rollback testing)"

git push origin main



***#Perform Manual Rollback***

\#Check rollout history:

kubectl rollout history deployment/cicd-app



\#Rollback to previous version:

kubectl rollout undo deployment/cicd-app



\#Verify rollback success:

kubectl rollout status deployment/cicd-app

SERVICE\_URL=$(minikube service cicd-app-service --url)

curl $SERVICE\_URL



***#Test Automated Rollback via GitHub Actions***

1. Go to your GitHub repository
2. Click Actions → Rollback Deployment → Run workflow
3. Leave revision empty to rollback to previous version
4. Click "Run workflow"



###### \#Environment-specific deployments



kubectl create namespace staging

kubectl create namespace production

kubectl apply -k k8s-manifests/environments/staging/

kubectl apply -k k8s-manifests/environments/production/



\# Verify deployments

kubectl get deployments --all-namespaces

