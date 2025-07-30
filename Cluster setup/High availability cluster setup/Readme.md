#### **High Availability Cluster Configuration**



1. ###### Connect to nodes



\#Note down the IP addresses of all nodes:

Master nodes: master1, master2, master3

Worker nodes: worker1, worker2

etcd nodes: etcd1, etcd2, etcd3

Load balancer: lb1



\#SSH into each node to verify connectivity:

ssh ubuntu@<node-ip>



###### 2\. Configure Hostnames and Host Resolution



**A. Set hostnames**



\# On master1

sudo hostnamectl set-hostname master1



\# On master2

sudo hostnamectl set-hostname master2



\# On master3

sudo hostnamectl set-hostname master3



\# On worker1

sudo hostnamectl set-hostname worker1



\# On worker2

sudo hostnamectl set-hostname worker2



\# On etcd1

sudo hostnamectl set-hostname etcd1



\# On etcd2

sudo hostnamectl set-hostname etcd2



\# On etcd3

sudo hostnamectl set-hostname etcd3



\# On lb1

sudo hostnamectl set-hostname lb1



**B. Set host resolution**



\# Update the /etc/hosts file on all nodes with the following entries: Replace with actual IP addresses

10.0.1.10 master1

10.0.1.11 master2

10.0.1.12 master3

10.0.1.20 worker1

10.0.1.21 worker2

10.0.1.30 etcd1

10.0.1.31 etcd2

10.0.1.32 etcd3

10.0.1.40 lb1

10.0.1.100 k8s-api.local



**3. Install Common Dependencies on all nodes**



a. Update the system and install required packages:

sudo apt update \&\& sudo apt upgrade -y

sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release



b. Disable swap (required for Kubernetes):

sudo swapoff -a

sudo sed -i '/ swap / s/^\\(.\*\\)$/#\\1/g' /etc/fstab



c. Load required kernel modules:

sudo tee /etc/modules-load.d/k8s.conf <<EOF

overlay

br\_netfilter

EOF



sudo modprobe overlay

sudo modprobe br\_netfilter



d. Configure sysctl parameters:

sudo tee /etc/sysctl.d/k8s.conf <<EOF

net.bridge.bridge-nf-call-iptables  = 1

net.bridge.bridge-nf-call-ip6tables = 1

net.ipv4.ip\_forward                 = 1

EOF



sudo sysctl --system



##### **Set Up External etcd Cluster**

###### 

1. ###### Setup



**#Install etcd on etcd Nodes**

ETCD\_VERSION="v3.5.9"

curl -L https://github.com/etcd-io/etcd/releases/download/${ETCD\_VERSION}/etcd-${ETCD\_VERSION}-linux-amd64.tar.gz -o etcd-${ETCD\_VERSION}-linux-amd64.tar.gz



tar xzf etcd-${ETCD\_VERSION}-linux-amd64.tar.gz

sudo mv etcd-${ETCD\_VERSION}-linux-amd64/etcd\* /usr/local/bin/

sudo chmod +x /usr/local/bin/etcd\*



**#Create etcd user and directories**

sudo useradd -r -s /bin/false etcd

sudo mkdir -p /etc/etcd /var/lib/etcd

sudo chown etcd:etcd /var/lib/etcd

sudo chmod 700 /var/lib/etcd



###### 2\. Generate a certificate



**#Generate etcd Certificate on etcd1**

mkdir -p ~/etcd-certs

cd ~/etcd-certs



\# Generate CA private key

openssl genrsa -out ca-key.pem 2048



\# Generate CA certificate

openssl req -new -x509 -key ca-key.pem -out ca.pem -days 365 -subj "/CN=etcd-ca"



**# Create certificate configuration**

cat > etcd-csr.conf <<EOF

\[req]

distinguished\_name = req\_distinguished\_name

req\_extensions = v3\_req

prompt = no



\[req\_distinguished\_name]

CN = etcd



\[v3\_req]

keyUsage = keyEncipherment, dataEncipherment

extendedKeyUsage = serverAuth, clientAuth

subjectAltName = @alt\_names



\[alt\_names]

DNS.1 = etcd1

DNS.2 = etcd2

DNS.3 = etcd3

DNS.4 = localhost

IP.1 = 10.0.1.30

IP.2 = 10.0.1.31

IP.3 = 10.0.1.32

IP.4 = 127.0.0.1

EOF



\# Generate etcd server private key

openssl genrsa -out etcd-key.pem 2048



**# Generate etcd server certificate signing request**

openssl req -new -key etcd-key.pem -out etcd.csr -config etcd-csr.conf



\# Generate etcd server certificate

openssl x509 -req -in etcd.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out etcd.pem -days 365 -extensions v3\_req -extfile etcd-csr.conf



###### 3\. Copy certificates to all etcd nodes



\# Copy to etcd2

scp ca.pem etcd.pem etcd-key.pem ubuntu@etcd2:~/

ssh ubuntu@etcd2 "sudo mv \*.pem /etc/etcd/ \&\& sudo chown etcd:etcd /etc/etcd/\*.pem"



\# Copy to etcd3

scp ca.pem etcd.pem etcd-key.pem ubuntu@etcd3:~/

ssh ubuntu@etcd3 "sudo mv \*.pem /etc/etcd/ \&\& sudo chown etcd:etcd /etc/etcd/\*.pem"



\# Move certificates on etcd1

sudo mv \*.pem /etc/etcd/

sudo chown etcd:etcd /etc/etcd/\*.pem



###### 4\. Configure etcd Cluster



1. **Create etcd configuration on etcd1**

sudo tee /etc/etcd/etcd.conf <<EOF

ETCD\_NAME=etcd1

ETCD\_DATA\_DIR=/var/lib/etcd

ETCD\_LISTEN\_PEER\_URLS=https://10.0.1.30:2380

ETCD\_LISTEN\_CLIENT\_URLS=https://10.0.1.30:2379,https://127.0.0.1:2379

ETCD\_INITIAL\_ADVERTISE\_PEER\_URLS=https://10.0.1.30:2380

ETCD\_ADVERTISE\_CLIENT\_URLS=https://10.0.1.30:2379

ETCD\_INITIAL\_CLUSTER=etcd1=https://10.0.1.30:2380,etcd2=https://10.0.1.31:2380,etcd3=https://10.0.1.32:2380

ETCD\_INITIAL\_CLUSTER\_STATE=new

ETCD\_INITIAL\_CLUSTER\_TOKEN=etcd-cluster

ETCD\_CERT\_FILE=/etc/etcd/etcd.pem

ETCD\_KEY\_FILE=/etc/etcd/etcd-key.pem

ETCD\_TRUSTED\_CA\_FILE=/etc/etcd/ca.pem

ETCD\_PEER\_CERT\_FILE=/etc/etcd/etcd.pem

ETCD\_PEER\_KEY\_FILE=/etc/etcd/etcd-key.pem

ETCD\_PEER\_TRUSTED\_CA\_FILE=/etc/etcd/ca.pem

ETCD\_PEER\_CLIENT\_CERT\_AUTH=true

ETCD\_CLIENT\_CERT\_AUTH=true

EOF



**2. Create etcd configuration on etcd2**

sudo tee /etc/etcd/etcd.conf <<EOF

ETCD\_NAME=etcd2

ETCD\_DATA\_DIR=/var/lib/etcd

ETCD\_LISTEN\_PEER\_URLS=https://10.0.1.31:2380

ETCD\_LISTEN\_CLIENT\_URLS=https://10.0.1.31:2379,https://127.0.0.1:2379

ETCD\_INITIAL\_ADVERTISE\_PEER\_URLS=https://10.0.1.31:2380

ETCD\_ADVERTISE\_CLIENT\_URLS=https://10.0.1.31:2379

ETCD\_INITIAL\_CLUSTER=etcd1=https://10.0.1.30:2380,etcd2=https://10.0.1.31:2380,etcd3=https://10.0.1.32:2380

ETCD\_INITIAL\_CLUSTER\_STATE=new

ETCD\_INITIAL\_CLUSTER\_TOKEN=etcd-cluster

ETCD\_CERT\_FILE=/etc/etcd/etcd.pem

ETCD\_KEY\_FILE=/etc/etcd/etcd-key.pem

ETCD\_TRUSTED\_CA\_FILE=/etc/etcd/ca.pem

ETCD\_PEER\_CERT\_FILE=/etc/etcd/etcd.pem

ETCD\_PEER\_KEY\_FILE=/etc/etcd/etcd-key.pem

ETCD\_PEER\_TRUSTED\_CA\_FILE=/etc/etcd/ca.pem

ETCD\_PEER\_CLIENT\_CERT\_AUTH=true

ETCD\_CLIENT\_CERT\_AUTH=true

EOF



**3. Create etcd configuration on etcd3**

sudo tee /etc/etcd/etcd.conf <<EOF

ETCD\_NAME=etcd3

ETCD\_DATA\_DIR=/var/lib/etcd

ETCD\_LISTEN\_PEER\_URLS=https://10.0.1.32:2380

ETCD\_LISTEN\_CLIENT\_URLS=https://10.0.1.32:2379,https://127.0.0.1:2379

ETCD\_INITIAL\_ADVERTISE\_PEER\_URLS=https://10.0.1.32:2380

ETCD\_ADVERTISE\_CLIENT\_URLS=https://10.0.1.32:2379

ETCD\_INITIAL\_CLUSTER=etcd1=https://10.0.1.30:2380,etcd2=https://10.0.1.31:2380,etcd3=https://10.0.1.32:2380

ETCD\_INITIAL\_CLUSTER\_STATE=new

ETCD\_INITIAL\_CLUSTER\_TOKEN=etcd-cluster

ETCD\_CERT\_FILE=/etc/etcd/etcd.pem

ETCD\_KEY\_FILE=/etc/etcd/etcd-key.pem

ETCD\_TRUSTED\_CA\_FILE=/etc/etcd/ca.pem

ETCD\_PEER\_CERT\_FILE=/etc/etcd/etcd.pem

ETCD\_PEER\_KEY\_FILE=/etc/etcd/etcd-key.pem

ETCD\_PEER\_TRUSTED\_CA\_FILE=/etc/etcd/ca.pem

ETCD\_PEER\_CLIENT\_CERT\_AUTH=true

ETCD\_CLIENT\_CERT\_AUTH=true

EOF



###### 5\. Create the systemd service file on all etcd nodes



sudo tee /etc/systemd/system/etcd.service <<EOF

\[Unit]

Description=etcd key-value store

Documentation=https://github.com/etcd-io/etcd

After=network.target



\[Service]

Type=notify

User=etcd

EnvironmentFile=/etc/etcd/etcd.conf

ExecStart=/usr/local/bin/etcd

Restart=always

RestartSec=10s

LimitNOFILE=40000



\[Install]

WantedBy=multi-user.target

EOF



###### 6\. Start etcd on all nodes simultaneously



\# On all etcd nodes

sudo systemctl daemon-reload

sudo systemctl enable etcd

sudo systemctl start etcd

Verify the cluster status:



\# On any etcd node

sudo ETCDCTL\_API=3 etcdctl \\

&nbsp; --endpoints=https://127.0.0.1:2379 \\

&nbsp; --cacert=/etc/etcd/ca.pem \\

&nbsp; --cert=/etc/etcd/etcd.pem \\

&nbsp; --key=/etc/etcd/etcd-key.pem \\

&nbsp; endpoint health



##### **Set Up Load Balancer for API Servers**



1. ###### Install and Configure HAProxy on the load balancer node (lb1):



Install HAProxy:

sudo apt update

sudo apt install -y haproxy

Configure HAProxy:

sudo tee /etc/haproxy/haproxy.cfg <<EOF

global

&nbsp;   log stdout local0

&nbsp;   chroot /var/lib/haproxy

&nbsp;   stats socket /run/haproxy/admin.sock mode 660 level admin

&nbsp;   stats timeout 30s

&nbsp;   user haproxy

&nbsp;   group haproxy

&nbsp;   daemon



defaults

&nbsp;   mode http

&nbsp;   log global

&nbsp;   option httplog

&nbsp;   option dontlognull

&nbsp;   option log-health-checks

&nbsp;   option forwardfor except 127.0.0.0/8

&nbsp;   option redispatch

&nbsp;   retries 3

&nbsp;   timeout http-request 10s

&nbsp;   timeout queue 20s

&nbsp;   timeout connect 10s

&nbsp;   timeout client 20s

&nbsp;   timeout server 20s

&nbsp;   timeout http-keep-alive 10s

&nbsp;   timeout check 10s



frontend k8s-api-frontend

&nbsp;   bind \*:6443

&nbsp;   mode tcp

&nbsp;   option tcplog

&nbsp;   default\_backend k8s-api-backend



backend k8s-api-backend

&nbsp;   mode tcp

&nbsp;   option tcplog

&nbsp;   option tcp-check

&nbsp;   balance roundrobin

&nbsp;   default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100

&nbsp;   server master1 10.0.1.10:6443 check

&nbsp;   server master2 10.0.1.11:6443 check

&nbsp;   server master3 10.0.1.12:6443 check



listen stats

&nbsp;   bind \*:8404

&nbsp;   stats enable

&nbsp;   stats uri /stats

&nbsp;   stats refresh 30s

&nbsp;   stats admin if TRUE

EOF



###### 2\. Start and enable HAProxy



sudo systemctl enable haproxy

sudo systemctl start haproxy

sudo systemctl status haproxy



##### **Install Container Runtime and Kubernetes Components**



1. ###### Install Docker on Master and Worker Nodes



\# Add Docker's official GPG key

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg



\# Add Docker repository

echo "deb \[arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb\_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null



\# Install Docker

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io



###### 2\. Configure Docker daemon



sudo tee /etc/docker/daemon.json <<EOF

{

&nbsp; "exec-opts": \["native.cgroupdriver=systemd"],

&nbsp; "log-driver": "json-file",

&nbsp; "log-opts": {

&nbsp;   "max-size": "100m"

&nbsp; },

&nbsp; "storage-driver": "overlay2"

}

EOF



sudo systemctl daemon-reload

sudo systemctl restart docker



###### 3\. Install Kubernetes Components on all master and worker nodes





**a. Add Kubernetes repository:**

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg



echo "deb \[signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list



**b. Install kubelet, kubeadm, and kubectl**

sudo apt update

sudo apt install -y kubelet=1.28.2-00 kubeadm=1.28.2-00 kubectl=1.28.2-00

sudo apt-mark hold kubelet kubeadm kubectl



**c. Configure kubelet**

sudo tee /etc/default/kubelet <<EOF

KUBELET\_EXTRA\_ARGS=--cgroup-driver=systemd

EOF



sudo systemctl daemon-reload

sudo systemctl restart kubelet



##### **Initialize first master node**



a. Copy etcd certificates from etcd1 to all master nodes:



\# On etcd1, copy certificates to master nodes

scp /etc/etcd/ca.pem /etc/etcd/etcd.pem /etc/etcd/etcd-key.pem ubuntu@master1:~/

scp /etc/etcd/ca.pem /etc/etcd/etcd.pem /etc/etcd/etcd-key.pem ubuntu@master2:~/

scp /etc/etcd/ca.pem /etc/etcd/etcd.pem /etc/etcd/etcd-key.pem ubuntu@master3:~/

On each master node, move the certificates:



\# On all master nodes

sudo mkdir -p /etc/kubernetes/pki/etcd

sudo mv ~/ca.pem /etc/kubernetes/pki/etcd/

sudo mv ~/etcd.pem /etc/kubernetes/pki/etcd/

sudo mv ~/etcd-key.pem /etc/kubernetes/pki/etcd/



b. Create the kubeadm configuration file on master1:

sudo ls /etc/Kubernetes

kubectl apply -f /etc/kubernetes/kubeadm-config.yaml



c. Initialize the cluster on master1:

sudo kubeadm init --config=/etc/kubernetes/kubeadm-config.yaml --upload-certs

Important: Save the output from this command, especially the join commands for additional masters and workers.



d. Set up kubectl for the ubuntu user:

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config



e. Install Pod Network Add-on



\#Install Flannel CNI plugin:

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml



\#Verify the first master is ready:

kubectl get nodes

kubectl get pods -n kube-system



##### **Join Additional Master Nodes**



1. ###### Master2: On master2, run the join command from the kubeadm init output:



sudo kubeadm join k8s-api.local:6443 --token <token> \\

&nbsp;   --discovery-token-ca-cert-hash sha256:<hash> \\

&nbsp;   --control-plane --certificate-key <certificate-key>



Set up kubectl:

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config



###### 2\. Master3: On master3, run the same join command:



sudo kubeadm join k8s-api.local:6443 --token <token> \\

&nbsp;   --discovery-token-ca-cert-hash sha256:<hash> \\

&nbsp;   --control-plane --certificate-key <certificate-key>



Set up kubectl:

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config



###### 3\. Check that all master nodes are ready:



kubectl get nodes

kubectl get pods -n kube-system -o wide

##### 

##### **Join Worker Nodes**



1. ###### On worker1 and worker2, run the worker join command:

sudo kubeadm join k8s-api.local:6443 --token <token> \\

&nbsp;   --discovery-token-ca-cert-hash sha256:<hash>

###### 

###### 2\. Verify Cluster Status:

From any master node, verify all nodes are ready:

kubectl get nodes

kubectl get pods -n kube-system



###### 3\. Label worker nodes:

kubectl label node worker1 node-role.kubernetes.io/worker=worker

kubectl label node worker2 node-role.kubernetes.io/worker=worker



##### **Test Failover Scenarios**



1. Create a test deployment to verify cluster functionality:



kubectl create deployment nginx-test --image=nginx:latest --replicas=3

kubectl expose deployment nginx-test --port=80 --type=NodePort

kubectl get pods -o wide

kubectl get services



2\. Test API Server High Availability:



Verify you can access the cluster through the load balancer:

kubectl --server=https://k8s-api.local:6443 get nodes



Check HAProxy stats:

curl http://lb1:8404/stats



3\. Simulate Master Node Failure



**Stop master1:**

\# On master1

sudo systemctl stop kubelet

sudo systemctl stop docker



**Verify cluster still functions from master2 or master3:**

\# On master2 or master3

kubectl get nodes

kubectl get pods

kubectl scale deployment nginx-test --replicas=5



**Verify the load balancer detects the failure:**

curl http://lb1:8404/stats



4\. Test etcd Cluster Resilience



**Stop one etcd node:**

\# On etcd1

sudo systemctl stop etcd



**Verify cluster operations continue:**

\# From any master node

kubectl get nodes

kubectl create deployment test-failover --image=nginx:latest



**Check etcd cluster health:**

\# On etcd2 or etcd3

sudo ETCDCTL\_API=3 etcdctl \\

&nbsp; --endpoints=https://127.0.0.1:2379 \\

&nbsp; --cacert=/etc/etcd/ca.pem \\

&nbsp; --cert=/etc/etcd/etcd.pem \\

&nbsp; --key=/etc/etcd/etcd-key.pem \\

&nbsp; endpoint health



5\. Recovery Testing



**Restart the stopped services:**

\# On master1

sudo systemctl start docker

sudo systemctl start kubelet



\# On etcd1

sudo systemctl start etcd



**Verify full cluster recovery:**

kubectl get nodes

kubectl get pods -n kube-system



##### **Troubleshooting Tips**



###### Issue: etcd cluster fails to start 



Verify all etcd nodes have correct certificates

Check firewall rules allow ports 2379 and 2380

Ensure all etcd nodes start simultaneously



###### Issue: kubeadm init fails with etcd connection error



Verify etcd cluster is healthy

Check certificate paths in kubeadm configuration

Ensure etcd endpoints are reachable from master nodes



###### Issue: Additional masters fail to join



Verify the certificate key hasn't expired

Check load balancer is properly configured

Ensure all required ports are open



###### Issue: Pods stuck in Pending state



Check CNI plugin installation

Verify node resources are sufficient

Check for taints on nodes



###### Verification Commands



\# Check cluster status

kubectl cluster-info

kubectl get componentstatuses



\# Check etcd health

sudo ETCDCTL\_API=3 etcdctl \\

&nbsp; --endpoints=https://etcd1:2379,https://etcd2:2379,https://etcd3:2379 \\

&nbsp; --cacert=/etc/kubernetes/pki/etcd/ca.pem \\

&nbsp; --cert=/etc/kubernetes/pki/etcd/etcd.pem \\

&nbsp; --key=/etc/kubernetes/pki/etcd/etcd-key.pem \\

&nbsp; endpoint health



\# Check load balancer

curl -k https://k8s-api.local:6443/version

