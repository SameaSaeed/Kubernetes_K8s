#!/bin/bash
echo "Completing canary rollout..."
echo "Scaling canary version to full capacity..."

# Scale canary to full capacity
kubectl scale deployment sample-app-v3 --replicas=3

# Scale down old version
kubectl scale deployment sample-app-v1 --replicas=0

echo "Rollout completed!"
kubectl get deployments