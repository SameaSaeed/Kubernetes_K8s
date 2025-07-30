#!/bin/bash
echo "Monitoring Istio security events..."

# Monitor authentication failures
kubectl logs -n istio-system -l app=istiod --tail=100 | grep -i "authentication\|authorization\|tls"

# Monitor proxy access logs
kubectl logs -l app=productpage -c istio-proxy --tail=50

# Check certificate rotation events
kubectl get events --field-selector reason=SecretRotated -n istio-system