#!/bin/bash

echo "=== CNI Plugin Comparison ==="
echo ""

echo "Current CNI Configuration:"
ls -la /etc/cni/net.d/

echo ""
echo "Calico Configuration Details:"
if [ -f /etc/cni/net.d/10-calico.conflist ]; then
    cat /etc/cni/net.d/10-calico.conflist | jq '.'
fi

echo ""
echo "Network Interface Information:"
ip addr show | grep -E "(cali|flannel|docker|eth)"

echo ""
echo "Routing Table:"
ip route show

echo ""
echo "Calico Node Status:"
kubectl get nodes -o wide