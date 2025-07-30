#!/bin/bash

echo "=== Node Information ==="
kubectl get nodes --show-labels

echo -e "\n=== Node Taints ==="
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    echo "Node: $node"
    kubectl describe node $node | grep -i taint || echo "  No taints"
    echo
done

echo "=== Pod Distribution ==="
kubectl get pods -o wide --all-namespaces | grep -v kube-system

echo -e "\n=== Pending Pods ==="
kubectl get pods --all-namespaces --field-selector=status.phase=Pending

echo -e "\n=== Recent Events ==="
kubectl get events --sort-by=.metadata.creationTimestamp | tail -10