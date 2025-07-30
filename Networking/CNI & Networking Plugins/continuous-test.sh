#!/bin/bash

NAMESPACE="network-test"
FIRST_POD=$(kubectl get pods -n $NAMESPACE -l app=connectivity-test -o jsonpath='{.items[0].metadata.name}')
SECOND_POD=$(kubectl get pods -n $NAMESPACE -l app=connectivity-test -o jsonpath='{.items[1].metadata.name}')
SECOND_POD_IP=$(kubectl get pod $SECOND_POD -n $NAMESPACE -o jsonpath='{.status.podIP}')

echo "Starting continuous connectivity test..."
echo "From: $FIRST_POD"
echo "To: $SECOND_POD ($SECOND_POD_IP)"
echo ""

for i in {1..20}; do
    echo -n "Test $i: "
    if kubectl exec -n $NAMESPACE $FIRST_POD -- ping -c 1 -W 2 $SECOND_POD_IP > /dev/null 2>&1; then
        echo "✓ SUCCESS"
    else
        echo "✗ FAILED"
    fi
    sleep 2
done