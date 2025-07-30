##### A. Identifying Threats



###### 1\. Identify Lateral Movement Opportunities

Analyze network segmentation and lateral movement risks:



\# Test network connectivity between different tiers

echo "Testing lateral movement possibilities..."



\# From frontend to backend (expected)

kubectl exec -it $(kubectl get pod -l app=web-frontend -o jsonpath='{.items\[0].metadata.name}') -- wget -qO- --timeout=5 http://api-service:8080 \&\& echo "Frontend → Backend: ACCESSIBLE"



\# From frontend to database (should be restricted)

kubectl exec -it $(kubectl get pod -l app=web-frontend -o jsonpath='{.items\[0].metadata.name}') -- nc -zv mysql-service 3306 \&\& echo "Frontend → Database: ACCESSIBLE (RISK!)"



\# From backend to database (expected)

kubectl exec -it $(kubectl get pod -l app=api-backend -o jsonpath='{.items\[0].metadata.name}') -- nc -zv mysql-service 3306 \&\& echo "Backend → Database: ACCESSIBLE"



###### 2\. Assess Container and Image Security

Examine container images and configurations for vulnerabilities:



\# Check image information

kubectl get pods -o jsonpath='{range .items\[\*]}{.metadata.name}{"\\t"}{.spec.containers\[\*].image}{"\\n"}{end}'



\# Examine resource limits and requests

kubectl describe pods | grep -A 5 -B 5 -i "limits\\|requests"



\# Check for secrets and environment variables

kubectl get pods -o jsonpath='{range .items\[\*]}{.metadata.name}{"\\t"}{.spec.containers\[\*].env\[\*]}{"\\n"}{end}'



##### B. Implement Security



1. ###### Pod Security Admission

\# Label namespace with Pod Security Standards

kubectl label namespace ecommerce-app pod-security.kubernetes.io/enforce=restricted

kubectl label namespace ecommerce-app pod-security.kubernetes.io/audit=restricted

kubectl label namespace ecommerce-app pod-security.kubernetes.io/warn=restricted



\# Verify labels

kubectl get namespace ecommerce-app --show-labels



\# Create secret for database credentials as in the secrets lab



\# Deploy secure versions

kubectl apply -f secure-database.yaml

kubectl apply -f secure-backend.yaml

kubectl apply -f secure-frontend.yaml



\# Wait for deployments to be ready

kubectl wait --for=condition=available deployment/secure-mysql-db --timeout=300s

kubectl wait --for=condition=available deployment/secure-api-backend --timeout=300s

kubectl wait --for=condition=available deployment/secure-web-frontend --timeout=300s

###### 

###### 2\. Implement Network Isolation

kubectl apply -f network-policies.yaml



\# Describe network policies

kubectl describe networkpolicy default-deny-ingress



\# Test Network isolation

echo "Testing network isolation..."



\# Test 1: Frontend should be able to reach backend

echo "Test 1: Frontend → Backend (should work)"

kubectl exec -it $(kubectl get pod -l app=secure-web-frontend -o jsonpath='{.items\[0].metadata.name}') -- wget -qO- --timeout=5 http://secure-api-service:8080 \&\& echo "SUCCESS: Frontend can reach backend" || echo "FAILED: Frontend cannot reach backend"



\# Test 2: Frontend should NOT be able to reach database directly

echo "Test 2: Frontend → Database (should fail)"

kubectl exec -it $(kubectl get pod -l app=secure-web-frontend -o jsonpath='{.items\[0].metadata.name}') -- nc -zv secure-mysql-service 3306 \&\& echo "FAILED: Frontend can reach database (security issue!)" || echo "SUCCESS: Frontend blocked from database"



\# Test 3: Backend should be able to reach database

echo "Test 3: Backend → Database (should work)"

kubectl exec -it $(kubectl get pod -l app=secure-api-backend -o jsonpath='{.items\[0].metadata.name}') -- nc -zv secure-mysql-service 3306 \&\& echo "SUCCESS: Backend can reach database" || echo "FAILED: Backend cannot reach database"



###### 3\. Implement additional security controls

kubectl apply -f additional-security-controls.yaml



###### 4\. Validating and Testing

chmod +x security-validation.sh

./security-validation.sh



\#Generate report



