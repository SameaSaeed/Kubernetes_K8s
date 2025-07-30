### **Observability**



##### 1\. Set up Prometheus



\# Create monitoring namespace

kubectl create namespace monitoring



\# Add Prometheus community Helm repository

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts



\# Update Helm repositories

helm repo update



\# Install Prometheus stack (includes Prometheus, Grafana, and AlertManager)

helm install prometheus prometheus-community/kube-prometheus-stack \\

  --namespace monitoring \\

  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \\

  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false



&nbsp;					OR



\# Install Prometheus with custom values

helm install prometheus prometheus-community/kube-prometheus-stack \\

&nbsp; --namespace monitoring \\

&nbsp; --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=10Gi \\

&nbsp; --set grafana.adminPassword=admin123 \\

&nbsp; --set alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage=5Gi





\# Uninstall Prometheus stack (If so)

helm uninstall prometheus -n monitoring



\# Wait for all pods to be ready (this may take 2-3 minutes)

kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s



\# Check logs

kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus



\# Port forward Prometheus service

kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 \&



\# Note: The \& runs the command in background

You can now access Prometheus at http://localhost:9090



\# Get Grafana admin password

kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

echo



echo "Grafana is accessible at http://localhost:3000"

echo "Username: admin"

echo "Password: admin123"



\# Port forward Grafana service

kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 \&



\# Stop port forwarding processes (If so)

pkill -f "kubectl port-forward"



##### 2\. Set Prometheus to scrape metrics:



\# View Prometheus configuration

kubectl get configmap -n monitoring prometheus-kube-prometheus-prometheus-rulefiles-0 -o yaml

 

\# Deploy app

kubectl apply -f sample-app.yaml

kubectl apply -f ServiceMonitor.yaml



\#In Grafana,

Open your web browser and navigate to http://localhost:3000

Login with username admin and password admin123

The Prometheus data source should already be configured automatically

Verify by going to Configuration > Data Sources and checking that Prometheus is listed

The URL should be: http://prometheus-kube-prometheus-prometheus:9090



##### 3\. Create a Grafana dashboard:



###### **A. Pre-built Kubernetes Dashboard**



In Grafana, click the + icon → Import

Enter dashboard ID: 315 (Kubernetes cluster monitoring dashboard)

Click Load

Select Prometheus as the data source

Click Import



###### **B. Custom dashboard for node-specific metrics**



Click + → Dashboard → Add new panel



Configure the first panel:



Title: CPU Usage by Node

Query: 100 - (avg by (instance) (rate(node\_cpu\_seconds\_total{mode="idle"}\[5m])) \* 100)

Visualization: Time series

Click Apply

Add another panel:



Title: Memory Usage by Node

Query: (1 - (node\_memory\_MemAvailable\_bytes / node\_memory\_MemTotal\_bytes)) \* 100

Visualization: Stat

Unit: Percent (0-100)

Click Apply

Add third panel:



Title: Disk Usage

Query: 100 - ((node\_filesystem\_avail\_bytes{mountpoint="/"} / node\_filesystem\_size\_bytes{mountpoint="/"}) \* 100)

Visualization: Gauge

Unit: Percent (0-100)

Click Apply

Save the dashboard:



Click Save (disk icon)

Name: Custom Node Monitoring

Click Save



OR 



echo "Custom dashboard configuration created. Import this in Grafana UI:"

echo "1. Go to Grafana (http://localhost:3000)"

echo "2. Click '+' > Import"

echo "3. Copy and paste the contents of custom-dashboard.json"



###### **C. Pod Monitoring Dashboard**



Create new dashboard: + → Dashboard



Add panel for Pod CPU Usage:



Title: Pod CPU Usage

Query: sum(rate(container\_cpu\_usage\_seconds\_total{container!="POD",container!=""}\[5m])) by (pod)

Visualization: Time series

Add panel for Pod Memory Usage:



Title: Pod Memory Usage

Query: sum(container\_memory\_working\_set\_bytes{container!="POD",container!=""}) by (pod)

Visualization: Time series

Unit: Bytes

Add panel for Pod Count:



Title: Running Pods

Query: count(kube\_pod\_info)

Visualization: Stat

Save dashboard as Pod Monitoring



OR



\# Deploy the sample application

kubectl apply -f sample-app.yaml



\# Verify deployment

kubectl get pods -l app=sample-web-app

kubectl get svc sample-web-app-service



\# Deploy the load generator

kubectl apply -f load-generator.yaml



\# Check if it's running

kubectl get pod load-generator

kubectl logs load-generator



##### 4\. Setting alert rules



a.

\# Apply alert rules

kubectl apply -f cpu-usage-alerts.yaml

kubectl apply -f memory-usage-alerts.yaml

kubectl apply -f pod-alerts.yaml



\# Verify PrometheusRules are created

kubectl get prometheusrules -n monitoring



\# Check Prometheus web interface for alerts

\# Go to http://localhost:9090/alerts to see all configured alerts



\#Configure Grafana Alerting

1. In Grafana, go to your Custom Node Monitoring dashboard
2. Edit the CPU Usage by Node panel
3. Go to Alert tab
4. Click Create Alert
5. Configure alert condition:
   Query: A (use existing query)
   Condition: IS ABOVE 80
   Evaluation: Every 10s for 1m
6. Add notification:
   Name: High CPU Alert
   Message: CPU usage is critically high
7. Click Save



\#Test alert functionality

kubectl apply -f cpu-stress-test.yaml



\#Monitor the alerts in both Prometheus (http://localhost:9090/alerts) and Grafana to see if they trigger.



b. 



\# Apply the alert rules

kubectl apply -f prometheus-alerts.yaml



\# Apply the Alertmanager configuration

kubectl apply -f alertmanager-config.yaml



\# Restart Alertmanager to pick up new configuration

kubectl rollout restart statefulset/alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring



##### 5a. Monitor Performance Metrics:



A.

\# Check current resource usage

kubectl top pods



\# View detailed metrics for our sample app

kubectl describe pod -l app=sample-web-app



echo "Visit the following URLs to view your monitoring setup:"

echo "Prometheus: http://localhost:9090"

echo "Grafana: http://localhost:3000"

echo "Check the 'Sample Web App Performance' dashboard in Grafana"



B.

\# Apply the ServiceMonitor

kubectl apply -f service-monitor.yaml



\# Apply recording rules

kubectl apply -f recording-rules.yaml



##### 5b. Troubleshooting:



###### **A. Metrics are not showing up in Prometheus:**



\# Verify ServiceMonitor configuration

kubectl get servicemonitor -n monitoring -o yaml



\# Check Prometheus targets

Go to http://localhost:9090/targets



\# Verify service endpoints

kubectl get endpoints -n default



###### **B. Grafana cannot connect to Prometheus:**



**A.**

If metrics are not showing up in Grafana:



\# Check Prometheus targets

\# Go to http://localhost:9090/targets



\# Verify ServiceMonitor labels

kubectl get servicemonitor -n monitoring -o yaml



\# Check Prometheus configuration

kubectl get prometheus -n monitoring -o yaml





B.

\# Check Grafana logs

kubectl logs -n monitoring -l app.kubernetes.io/name=grafana



\# Verify Prometheus service

kubectl get svc -n monitoring prometheus-kube-prometheus-prometheus



\# Test connectivity from the Grafana pod

kubectl exec -n monitoring -it deployment/prometheus-grafana -- wget -qO- http://prometheus-kube-prometheus-prometheus:9090/api/v1/status/config



###### **C. Pods Not Starting**



\# Check pod status and events

kubectl describe pods -n monitoring



\# Check available resources

kubectl top nodes



\# Verify storage classes

kubectl get storageclass



###### **D. Alerts Not Firing**

###### 

\# Check PrometheusRule status

kubectl get prometheusrule -n monitoring



\# Verify Alertmanager configuration

kubectl logs -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager-0

