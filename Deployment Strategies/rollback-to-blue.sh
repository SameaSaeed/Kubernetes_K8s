#!/bin/bash
echo "Rolling back to Blue environment (v1)..."
kubectl patch service sample-app-service -p '{"spec":{"selector":{"app":"sample-app","version":"v1"}}}'
echo "Rollback completed. Verifying..."
kubectl get endpoints sample-app-service