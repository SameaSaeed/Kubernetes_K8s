###### 1\. Create an app, a service, and a DNS service



\# Test short service name (within same namespace)

kubectl exec dns-test-pod -- nslookup sample-web-service



\# Test fully qualified domain name (FQDN)

kubectl exec dns-test-pod -- nslookup sample-web-service.default.svc.cluster.local



\# Test connectivity to the service

kubectl exec dns-test-pod -- wget -qO- sample-web-service



\# Verify the DNS resolution shows the correct service IP:

kubectl get service sample-web-service -o wide



###### 2\. Modify CoreDNS Configuration to Add Custom Domain and Test



Check the current CoreDNS configuration:

kubectl get configmap coredns -n kube-system -o yaml



View the CoreDNS pods and their status:

kubectl get pods -n kube-system -l k8s-app=kube-dns



Examine the current Corefile configuration:

kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}' | cat



backup the original CoreDNS configuration:

kubectl get configmap coredns -n kube-system -o yaml > coredns-backup.yaml



Create a new CoreDNS configuration with a custom domain

kubectl apply -f custom-coredns-config.yaml



Restart CoreDNS pods to pick up the new configuration:

kubectl rollout restart deployment/coredns -n kube-system



Wait for the rollout to complete:

kubectl rollout status deployment/coredns -n kube-system



\# Test the custom domain we added

kubectl exec dns-test-pod -- nslookup api.mycompany.local



\# Test that regular Kubernetes DNS still works

kubectl exec dns-test-pod -- nslookup sample-web-service.default.svc.cluster.local



\#Create an additional custom entry by updating the hosts section:

kubectl apply -f updated-coredns-config.yaml

kubectl rollout restart deployment/coredns -n kube-system

kubectl rollout status deployment/coredns -n kube-system



\#Test the new custom entries:

kubectl exec dns-test-pod -- nslookup database.mycompany.local

kubectl exec dns-test-pod -- nslookup cache.mycompany.local



###### 3\. Troubleshoot DNS Resolution Issues



Apply the broken configuration:

kubectl apply -f broken-coredns-config.yaml

kubectl rollout restart deployment/coredns -n kube-system



Wait a moment and test DNS resolution (this should fail)

kubectl exec dns-test-pod -- nslookup sample-web-service



\# Get CoreDNS pod names

kubectl get pods -n kube-system -l k8s-app=kube-dns



\# Check logs from CoreDNS pods (replace pod name with actual name)

COREDNS\_POD=$(kubectl get pods -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items\[0].metadata.name}')

kubectl logs $COREDNS\_POD -n kube-system



\# Get logs from all CoreDNS pods

kubectl logs -l k8s-app=kube-dns -n kube-system --tail=50

Check the status of CoreDNS pods:

kubectl describe pods -l k8s-app=kube-dns -n kube-system



Apply the advanced test pod:

kubectl apply -f advanced-dns-test-pod.yaml

kubectl wait --for=condition=Ready pod/advanced-dns-test --timeout=60s

Perform comprehensive DNS troubleshooting:

\# Check DNS configuration in the pod

kubectl exec advanced-dns-test -- cat /etc/resolv.conf



\# Test DNS resolution with dig

kubectl exec advanced-dns-test -- dig sample-web-service.default.svc.cluster.local



\# Test direct connection to CoreDNS

kubectl exec advanced-dns-test -- dig @10.96.0.10 sample-web-service.default.svc.cluster.local



\# Check if CoreDNS service is accessible

kubectl exec advanced-dns-test -- nslookup kube-dns.kube-system.svc.cluster.local



Test network connectivity to CoreDNS:

\# Get CoreDNS service IP

COREDNS\_IP=$(kubectl get service kube-dns -n kube-system -o jsonpath='{.spec.clusterIP}')

echo "CoreDNS Service IP: $COREDNS\_IP"



\# Test connectivity to CoreDNS

kubectl exec advanced-dns-test -- nc -zv $COREDNS\_IP 53

###### 

###### 4\. Fix the DNS Issues



Restore the working CoreDNS configuration:

kubectl apply -f coredns-backup.yaml

kubectl rollout restart deployment/coredns -n kube-system

kubectl rollout status deployment/coredns -n kube-system



\#Verify DNS resolution is working again:

kubectl exec dns-test-pod -- nslookup sample-web-service

kubectl exec dns-test-pod -- nslookup sample-web-service.default.svc.cluster.local



\#Test with the advanced troubleshooting pod:

kubectl exec advanced-dns-test -- dig sample-web-service.default.svc.cluster.local



###### 5\. Moitoring CoreDNS Performance



Check CoreDNS metrics (if Prometheus is available):

\# Port forward to access CoreDNS metrics

kubectl port-forward -n kube-system svc/kube-dns 9153:9153 \&

PF\_PID=$!



\# Query metrics (in another terminal or after backgrounding)

curl http://localhost:9153/metrics | grep coredns



\# Stop port forwarding

kill $PF\_PID



Run the load test and monitor CoreDNS logs:

kubectl apply -f dns-load-test.yaml



\# Monitor CoreDNS logs during the test

kubectl logs -f -l k8s-app=kube-dns -n kube-system



###### 6\. Troubleshooting



Issue 1: Service not resolving: nslookup returns NXDOMAIN

kubectl get svc -A | grep service-name

(Check if service exists and is in the correct namespace)



Issue 2: CoreDNS pods not running: DNS queries timeout

kubectl get pods -n kube-system -l k8s-app=kube-dns

kubectl describe pods -n kube-system -l k8s-app=kube-dns

(Check CoreDNS pod status and restart if necessary)



Issue 3: Wrong DNS configuration: Custom domains not resolving

kubectl get configmap coredns -n kube-system -o yaml

(Verify CoreDNS ConfigMap syntax)



Issue 4: Network policy blocking DNS: DNS queries fail from specific pods

kubectl get networkpolicies -A

(Check network policies affecting DNS traffic)

