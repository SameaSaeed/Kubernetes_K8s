#!/bin/bash
echo "=== Deployment Health Check ==="
echo ""

echo "1. Deployment Status:"
kubectl get deployments -l app=sample-app

echo ""
echo "2. Pod Status:"
kubectl get pods -l app=sample-app -o wide

echo ""
echo "3. Service Status:"
kubectl get services -l app=sample-app

echo ""
echo "4. Recent Events:"
kubectl get events --sort-by=.metadata.creationTimestamp | tail -10

echo ""
echo "5. Resource Usage:"
kubectl top pods -l app=sample-app 2>/dev/null || echo "Metrics server not available"

echo ""
echo "6. Deployment History:"
kubectl rollout history deployment/sample-app-v1
kubectl rollout history deployment/sample-app-v3