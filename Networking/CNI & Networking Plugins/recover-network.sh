#!/bin/bash

echo "=== Network Recovery Procedures ==="

echo "1. Restarting CNI pods..."
kubectl delete pods -n calico-system -l k8s-app=calico-node
kubectl delete pods -n calico-system -l k8s-app=calico-kube-controllers

echo "2. Waiting for CNI pods to restart..."
kubectl wait --for=condition=Ready pod -l k8s-app=calico-node -n calico-system --timeout=120s
kubectl wait --for=condition=Ready pod -l k8s-app=calico-kube-controllers -n calico-system --timeout=120s

echo "3. Restarting CoreDNS..."
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system

echo "4. Verifying network connectivity..."
# Test basic connectivity
FIRST_POD=$(kubectl get pods -n network-test -l app=connectivity-test -o jsonpath='{.items[0].metadata.name}')
SECOND_POD=$(kubectl get pods -n network-test -l app=connectivity-test -o jsonpath='{.items[1].metadata.name}')

if [ -n "$FIRST_POD" ] && [ -n "$SECOND_POD" ]; then
    SECOND_POD_IP=$(kubectl get pod $SECOND_POD -n network-test -o jsonpath='{.status.podIP}')
    echo "Testing connectivity from $FIRST_POD to $SECOND_POD ($SECOND_POD_IP)..."
    
    if kubectl exec -n network-test $FIRST_POD -- ping -c 3 $SECOND_POD_IP; then
        echo "✓ Network recovery successful!"
    else
        echo "✗ Network recovery failed - further investigation needed"
    fi
else
    echo "⚠ Test pods not available - deploying new test pods..."
    kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: recovery-test-pod
  namespace: network-test
spec:
  containers:
  - name: test-container
    image: busybox:1.35
    command: ['sleep', '300']
EOF
fi

echo ""
echo "5. Final network status:"
kubectl get pods --all-namespaces -o wide | grep -E "(calico|coredns|network-test)"
