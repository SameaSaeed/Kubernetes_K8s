#!/bin/bash

echo "=== Deployment Status ==="
kubectl get deployment nginx-deployment

echo -e "\n=== Rollout History ==="
kubectl rollout history deployment/nginx-deployment

echo -e "\n=== Current Replica Sets ==="
kubectl get replicasets -l app=nginx

echo -e "\n=== Pod Details ==="
kubectl get pods -l app=nginx -o wide

echo -e "\n=== Deployment Description ==="
kubectl describe deployment nginx-deployment | grep -A 10 "RollingUpdateStrategy"