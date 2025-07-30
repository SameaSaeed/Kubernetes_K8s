#!/bin/bash

echo "=== Network Monitoring Dashboard ==="
echo "Timestamp: $(date)"
echo ""

echo "1. Node Status:"
kubectl get nodes -o wide

echo ""
echo "2. CNI Pod Status:"
kubectl get pods -n calico-system

echo ""
echo "3. Network Interfaces:"
ip addr show | grep -E "(cali|eth|lo)" -A 2

echo ""
echo "4. Active Connections:"
ss -tuln | head -10

echo ""
echo "5. Routing Table:"
ip route show | head -10

echo ""
echo "6. DNS Resolution Test:"
nslookup kubernetes.default.svc.cluster.local