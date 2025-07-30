#!/bin/bash
echo "Cleaning up lab resources..."

# Delete deployments
kubectl delete deployment sample-app-v1 sample-app-v2 sample-app-v3

# Delete services
kubectl delete service sample-app-service sample-app-blue sample-app-green

# Delete configmaps
kubectl delete configmap app-content-v1 app-content-v2 app-content-v3

# Kill any background processes
pkill -f "kubectl port-forward"

echo "Cleanup completed!"