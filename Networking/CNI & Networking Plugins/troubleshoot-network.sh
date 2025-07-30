#!/bin/bash

echo "=== Kubernetes Network Troubleshooting ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Cluster Status:"
kubectl cluster-info

echo ""
echo "2. Node Status and Details:"
kubectl get nodes -o wide
kubectl describe nodes | grep -E "(Name:|Conditions:|PodCIDR:|InternalIP:)"

echo ""
echo "3. CNI Plugin Status:"
kubectl get pods -n calico-system
kubectl get pods -n kube-system | grep -E "(coredns|kube-proxy)"

echo ""
echo "4. Network Configuration:"
echo "CNI Config Directory:"
ls -la /etc/cni/net.d/

echo ""
echo "Active CNI Configuration:"
if [ -f /etc/cni/net.d/10-calico.conflist ]; then
    echo "Calico Configuration:"
    cat /etc/cni/net.d/10-calico.conflist | jq '.plugins[0].ipam'
fi

echo ""
echo "5. Pod Network Status:"
kubectl get pods --all-namespaces -o wide | grep -v "kube-system"

echo ""
echo "6. Service Network Status:"
kubectl get services --all-namespaces

echo ""
echo "7. Network Policies:"
kubectl get networkpolicies --all-namespaces

echo ""
echo "8. System Network Interfaces:"
ip addr show | grep -E "(cali|flannel|docker|eth)" -A 3

echo ""
echo "9. Routing Information:"
ip route show

echo ""
echo "10. DNS Configuration:"
kubectl get configmap coredns -n kube-system -o yaml | grep -A 20 "Corefile:"
