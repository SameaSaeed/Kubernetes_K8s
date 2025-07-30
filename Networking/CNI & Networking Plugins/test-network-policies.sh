#!/bin/bash

echo "=== Network Policy Testing ==="

FRONTEND_POD=$(kubectl get pods -n frontend -l app=frontend -o jsonpath='{.items[0].metadata.name}')
BACKEND_POD=$(kubectl get pods -n backend -l app=backend -o jsonpath='{.items[0].metadata.name}')
DATABASE_POD=$(kubectl get pods -n database -l app=database -o jsonpath='{.items[0].metadata.name}')

BACKEND_SERVICE_IP=$(kubectl get service backend-service -n backend -o jsonpath='{.spec.clusterIP}')
DATABASE_SERVICE_IP=$(kubectl get service database-service -n database -o jsonpath='{.spec.clusterIP}')

echo "Test Pods:"
echo "  Frontend: $FRONTEND_POD"
echo "  Backend: $BACKEND_POD"
echo "  Database: $DATABASE_POD"
echo ""

echo "Service IPs:"
echo "  Backend: $BACKEND_SERVICE_IP"
echo "  Database: $DATABASE_SERVICE_IP"
echo ""

echo "1. Testing Frontend -> Backend (should SUCCEED):"
if kubectl exec -n frontend $FRONTEND_POD -- curl -m 5 -s http://$BACKEND_SERVICE_IP > /dev/null 2>&1; then
    echo "   ✓ Frontend can access Backend"
else
    echo "   ✗ Frontend cannot access Backend"
fi

echo ""
echo "2. Testing Frontend -> Database (should FAIL):"
if kubectl exec -n frontend $FRONTEND_POD -- nc -zv $DATABASE_SERVICE_IP 5432 > /dev/null 2>&1; then
    echo "   ✗ Frontend can access Database (Policy not working!)"
else
    echo "   ✓ Frontend cannot access Database (Policy working)"
fi

echo ""
echo "3. Testing Backend -> Database (should SUCCEED):"
if kubectl exec -n backend $BACKEND_POD -- nc -zv $DATABASE_SERVICE_IP 5432 > /dev/null 2>&1; then
    echo "   ✓ Backend can access Database"
else
    echo "   ✗ Backend cannot access Database"
fi

echo ""
echo "4. Current Network Policies:"
kubectl get networkpolicies --all-namespaces