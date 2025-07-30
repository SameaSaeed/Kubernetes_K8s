#!/bin/bash
echo "Monitoring Canary Deployment..."
echo "================================"

# Function to get version distribution
get_version_stats() {
    local total_requests=50
    local v1_count=0
    local v3_count=0
    
    echo "Sending $total_requests requests to measure traffic distribution..."
    
    for i in $(seq 1 $total_requests); do
        response=$(curl -s http://localhost:8080 | grep -o "Version [0-9.]*" | grep -o "[0-9.]*")
        if [[ "$response" == "1.0" ]]; then
            ((v1_count++))
        elif [[ "$response" == "3.0" ]]; then
            ((v3_count++))
        fi
    done
    
    echo "Results:"
    echo "  Version 1.0 (Stable): $v1_count requests ($(( v1_count * 100 / total_requests ))%)"
    echo "  Version 3.0 (Canary): $v3_count requests ($(( v3_count * 100 / total_requests ))%)"
}

# Monitor pod health
echo "Pod Status:"
kubectl get pods -l app=sample-app -o wide

echo ""
echo "Service Endpoints:"
kubectl get endpoints sample-app-service

echo ""
# Set up port forwarding if not already running
kubectl port-forward service/sample-app-service 8080:80 > /dev/null 2>&1 &
PORT_FORWARD_PID=$!
sleep 2

get_version_stats

# Clean up
kill $PORT_FORWARD_PID 2>/dev/null