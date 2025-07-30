#!/bin/bash

echo "=== Kubernetes Storage Monitoring ==="
echo "Date: $(date)"
echo

echo "=== PersistentVolumes ==="
kubectl get pv -o wide

echo
echo "=== PersistentVolumeClaims ==="
kubectl get pvc -o wide

echo
echo "=== Storage Usage in Pod ==="
POD_NAME=$(kubectl get pods -l app=storage-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$POD_NAME" ]; then
    echo "Pod: $POD_NAME"
    kubectl exec $POD_NAME -- df -h /data 2>/dev/null || echo "Pod not ready or not found"
    echo "Files in /data:"
    kubectl exec $POD_NAME -- ls -la /data 2>/dev/null || echo "Cannot access /data"
else
    echo "No storage-app pods found"
fi

echo
echo "=== Recent Storage Events ==="
kubectl get events --field-selector involvedObject.kind=PersistentVolume,involvedObject.kind=PersistentVolumeClaim --sort-by='.lastTimestamp' | tail -5