#!/bin/bash

NAMESPACE="network-test"
PODS=$(kubectl get pods -n $NAMESPACE -l app=connectivity-test -o jsonpath='{.items[*].metadata.name}')

echo "=== Pod Connectivity Test ==="
echo "Testing connectivity between all pods..."

for pod1 in $PODS; do
    echo ""
    echo "Testing from pod: $pod1"
    
    for pod2 in $PODS; do
        if [ "$pod1" != "$pod2" ]; then
            POD2_IP=$(kubectl get pod $pod2 -n $NAMESPACE -o jsonpath='{.status.podIP}')
            echo -n "  -> $pod2 ($POD2_IP): "
            
            if kubectl exec -n $NAMESPACE $pod1 -- ping -c 1 -W 2 $POD2_IP > /dev/null 2>&1; then
                echo "✓ SUCCESS"
            else
                echo "✗ FAILED"
            fi
        fi
    done
done