#### **HORIZONTAL POD SCALING**



1. ##### Create HPA resources



\# Create Deployment

kubectl apply -f php-apache-deployment.yaml



\# Metrics Server setup

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system

kubectl get deployment metrics-server -n kube-system

kubectl top nodes

kubectl top pods





\# Apply HPA configuration

kubectl apply -f hpa-config.yaml

kubectl describe hpa php-apache



##### 2\. Load testing



###### ***a. Create a load generator pod:***



kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh



\#Inside the load generator pod, run the following command to generate load:

while true; do wget -q -O- http://php-apache; done



###### ***b. Monitor scaling in real-time:***



\#Watch HPA status in real-time:

kubectl get hpa php-apache --watch



\#In another terminal, monitor pod scaling:

kubectl get pods -l app=php-apache --watch



\#Monitor resource usage:

watch kubectl top pods -l app=php-apache



\#Check HPA events to see scaling decisions:

kubectl describe hpa php-apache



\#View deployment events:

kubectl describe deployment php-apache



\#Check cluster events:

kubectl get events --sort-by=.metadata.creationTimestamp



\#Stop the load generator

Ctrl+C in the load generator terminal.



\#Monitor the scale-down process:

kubectl get hpa php-apache --watch



\#Observe how pods are terminated:

kubectl get pods -l app=php-apache --watch



###### ***c. Troubleshooting:*** HPA status shows "Unknown" for current metrics.



\#Check if metrics server is running:

kubectl get pods -n kube-system | grep metrics-server



\#Verify pod resource requests are set:

kubectl describe deployment php-apache



\#Check metrics server logs:

kubectl logs -n kube-system deployment/metrics-server



#### **VERTICAL POD SCALING**



1. ###### ***Create VPA resources***



git clone https://github.com/kubernetes/autoscaler.git

cd autoscaler/vertical-pod-autoscaler/

./hack/vpa-install.sh

kubectl get pods -n kube-system | grep vpa

kubectl delete hpa php-apache

kubectl apply -f vpa-config.yaml

kubectl describe vpa php-apache-vpa



###### ***2. Test for VPA***



**a. VPA with auto-updates:**



kubectl apply -f load-generator-deployment.yaml



\#Monitor VPA recommendations:

kubectl describe vpa php-apache-vpa



\#Check the current resource usage:

kubectl top pods -l app=php-apache



\#Watch for pod restarts as VPA applies new resource limits:

kubectl get pods -l app=php-apache --watch



\#Compare resource requests before and after VPA adjustment:

kubectl describe pod -l app=php-apache



**b. VPA in Recommendation-only Mode:**



\#View recommendations without automatic updates:

kubectl delete vpa php-apache-vpa

kubectl apply -f vpa-recommend-only.yaml



\#View recommendations without automatic updates:

kubectl describe vpa php-apache-vpa-recommend



###### ***3. Troubleshooting:*** VPA recommendations are generated, but pods are not updated.



\#Ensure VPA is in "Auto" mode:

kubectl describe vpa php-apache-vpa



\#Check VPA admission controller:

kubectl get pods -n kube-system | grep vpa-admission-controller



\#Verify no resource quotas are blocking updates:

kubectl describe resourcequota



#### **Optimizing Autoscaling Behaviour**



* Adjust scaling policies in HPA behavior section
* Modify stabilization windows
* Fine-tune target utilization percentages
