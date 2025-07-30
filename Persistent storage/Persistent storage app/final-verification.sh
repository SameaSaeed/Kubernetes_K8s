#!/bin/bash

echo "=== Final Lab Verification ==="
echo "Date: $(date)"
echo

# Check if main components exist
echo "1. Checking PersistentVolumes..."
kubectl get pv | grep -E "(lab-pv|lab-pv-2)" && echo "✓ PVs found" || echo "✗ PVs missing"

echo
echo "2. Checking PersistentVolumeClaims..."
kubectl get pvc | grep -E "(lab-pvc|lab-pvc-2)" && echo "✓ PVCs found" || echo "✗ PVCs missing"

echo
echo "3. Checking Applications..."
kubectl get deployments | grep -E "(storage-app|multi-volume-app)" && echo "✓ Applications found" || echo "✗ Applications missing"

echo
echo "4. Checking Data Persistence..."
STORAGE_POD=$(kubectl get pods -l app=storage-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$STORAGE_POD" ]; then
    if kubectl exec $STORAGE_POD -- test -f /data/timestamps.log 2>/dev/null; then
        LINE_COUNT=$(kubectl exec $STORAGE_POD -- wc -l /data/timestamps.log | awk '{print $1}')
        echo "✓ Data persistence verified - $LINE_COUNT log entries found"
    else
        echo "✗ Data persistence failed - log file not found"
    fi
else
    echo "✗ Storage app pod not found"
fi

echo
echo "5. Checking Multi-Volume Setup..."
MULTI_POD=$(kubectl get pods -l app=multi-volume-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ ! -z "$MULTI_POD" ]; then
    if kubectl exec $MULTI_POD -- test -f /data1/log1.txt 2>/dev/null && kubectl exec $MULTI_POD -- test -f /data2/log2.txt 2>/dev/null; then
        echo "✓ Multi-volume setup verified"
    else
        echo "✗ Multi-volume setup failed"
    fi
else
    echo "✗ Multi-volume app pod not found"
fi

echo
echo "=== Verification Complete ==="