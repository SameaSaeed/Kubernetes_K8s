#!/bin/bash

echo "=== Storage Cleanup Script ==="

# Delete deployments first
echo "Deleting deployments..."
kubectl delete deployment storage-app multi-volume-app --ignore-not-found=true

# Wait for pods to terminate
echo "Waiting for pods to terminate..."
kubectl wait --for=delete pod -l app=storage-app --timeout=60s 2>/dev/null || true
kubectl wait --for=delete pod -l app=multi-volume-app --timeout=60s 2>/dev/null || true

# Delete PVCs
echo "Deleting PVCs..."
kubectl delete pvc lab-pvc lab-pvc-2 large-pvc --ignore-not-found=true

# Delete PVs
echo "Deleting PVs..."
kubectl delete pv lab-pv lab-pv-2 --ignore-not-found=true

# Delete service
echo "Deleting service..."
kubectl delete service storage-app-service --ignore-not-found=true

echo "Cleanup completed!"

# Show remaining resources
echo "Remaining storage resources:"
kubectl get pv,pvc