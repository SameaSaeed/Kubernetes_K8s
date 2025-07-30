#### Setting up Kubernetes



###### a. Installations



\# Update package index

sudo apt update



\# Upgrade existing packages

sudo apt upgrade -y



\# Install essential packages

sudo apt install -y apt-transport-https ca-certificates curl software-properties-common



###### b. Disable swap 



\#temporarily

sudo swapoff -a



\# Disable swap permanently by commenting out swap entries

sudo sed -i '/ swap / s/^\\(.\*\\)$/#\\1/g' /etc/fstab



\# Verify swap is disabled

free -h



###### c. Configure Kernel Modules



\# Load required modules: 

sudo modprobe overlay

sudo modprobe br\_netfilter



\# Make modules persistent across reboots

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf

overlay

br\_netfilter

EOF



\# Configure sysctl parameters

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf

net.bridge.bridge-nf-call-iptables  = 1

net.bridge.bridge-nf-call-ip6tables = 1

net.ipv4.ip\_forward                 = 1

EOF



\# Apply sysctl parameters without reboot

sudo sysctl --system

###### 

###### d. containerd setup



\# Add Docker's official GPG key

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg



\# Add Docker repository

echo "deb \[arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb\_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null



\# Update package index

sudo apt update



\# Install containerd

sudo apt install -y containerd.io





\# Create containerd configuration directory

sudo mkdir -p /etc/containerd



\# Generate default configuration

sudo containerd config default | sudo tee /etc/containerd/config.toml



\# Configure containerd to use systemd cgroup driver

sudo sed -i 's/SystemdCgroup \\= false/SystemdCgroup \\= true/g' /etc/containerd/config.toml



\# Restart and enable containerd

sudo systemctl restart containerd

sudo systemctl enable containerd



\# Verify containerd is running

sudo systemctl status containerd



###### e. Kubernetes Components



\# Add Kubernetes signing key

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg



\# Add Kubernetes repository

echo 'deb \[signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list



\# Update package index

sudo apt update



\# Install kubelet, kubeadm, and kubectl

sudo apt install -y kubelet kubeadm kubectl



\# Prevent automatic updates of Kubernetes packages

sudo apt-mark hold kubelet kubeadm kubectl



\# Verify installation

kubeadm version

kubectl version --client

###### 

###### f. Initializing the K8s cluster



1\.

\# Initialize the cluster with kubeadm

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -I | awk '{print $1}')

Important: Save the kubeadm join command that appears at the end of the output. You'll need it to add worker nodes later.



Expected Output: You should see a message saying "Your Kubernetes control-plane has initialized successfully!"



2\.

\# Create .kube directory

mkdir -p $HOME/.kube



\# Copy admin configuration

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config



\# Change ownership of the config file

sudo chown $(id -u):$(id -g) $HOME/.kube/config



\# Verify kubectl configuration

kubectl cluster-info

Expected Output: You should see cluster information including the Kubernetes master URL.



3\.

\# Apply Flannel network plugin

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml



\# Wait for flannel pods to be ready

kubectl wait --for=condition=ready pod -l app=flannel -n kube-flannel --timeout=300s



4\.

\# Remove the master node taint

kubectl taint nodes --all node-role.kubernetes.io/control-plane-



\# Verify the taint removal

kubectl describe nodes | grep -i taint



5\.



a.

\# Check node status

kubectl get nodes



\# Get detailed node information

kubectl get nodes -o wide



b.

\# Check all system pods

kubectl get pods --all-namespaces



\# Check pods in kube-system namespace specifically

kubectl get pods -n kube-system



\# Wait for all pods to be running

kubectl wait --for=condition=ready pod --all -n kube-system --timeout=300s

Expected Output: All pods should show Running or Completed status.



c.

\# Check cluster component status

kubectl get componentstatuses



\# View cluster information

kubectl cluster-info



\# Check API server health

kubectl get --raw='/readyz?verbose'





###### 6\. Exploring the Cluster



a.

\# List all namespaces

kubectl get namespaces



\# Get cluster version information

kubectl version



\# View cluster configuration

kubectl config view



\# Check current context

kubectl config current-context



b.

\# Create a test deployment

kubectl create deployment nginx-test --image=nginx:latest



\# Expose the deployment as a service

kubectl expose deployment nginx-test --port=80 --type=NodePort



\# Check deployment status

kubectl get deployments



\# Check pods

kubectl get pods



\# Check services

kubectl get services



c.

\# Get detailed information about the nginx pod

kubectl describe pod $(kubectl get pods -l app=nginx-test -o jsonpath='{.items\[0].metadata.name}')



\# Check service details

kubectl get service nginx-test



\# Test the application (get the NodePort)

NODE\_PORT=$(kubectl get service nginx-test -o jsonpath='{.spec.ports\[0].nodePort}')

curl http://localhost:$NODE\_PORT



Expected Output: You should see the default nginx welcome page HTML.



d.

Check Resource Usage

\# Check node resource usage

kubectl top nodes



\# If metrics-server is not installed, install it

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml



\# Wait for metrics-server to be ready

kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s



e.

\# List available API resources

kubectl api-resources



\# Get API versions

kubectl api-versions



\# Check cluster events

kubectl get events --sort-by=.metadata.creationTimestamp



f.

\# Check network policies (if any)

kubectl get networkpolicies --all-namespaces



\# Verify DNS resolution

kubectl run test-dns --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes.default



###### 7\. Troubleshooting 



**Issue 1: Pods Stuck in Pending State**



\# Check pod events

kubectl describe pod <pod-name>



\# Check node resources

kubectl describe nodes



\# Verify network plugin installation

kubectl get pods -n kube-flannel



**Issue 2: kubelet Not Starting**



\# Check kubelet status

sudo systemctl status kubelet



\# View kubelet logs

sudo journalctl -xeu kubelet



\# Restart kubelet if needed

sudo systemctl restart kubelet



**Issue 3: Network Issues**



\# Check containerd status

sudo systemctl status containerd



\# Verify network configuration

ip route show



\# Check firewall rules

sudo iptables -L

