#### **Security Report**



echo "=== SECURITY LAB SUMMARY REPORT ==="

echo "Namespace: security-lab"

echo "Service Accounts Created: $(kubectl get sa -n security-lab --no-headers | wc -l)"

echo "Roles Created: $(kubectl get roles -n security-lab --no-headers | wc -l)"

echo "Role Bindings Created: $(kubectl get rolebindings -n security-lab --no-headers | wc -l)"

echo "Network Policies Active: $(kubectl get networkpolicies -n security-lab --no-headers | wc -l)"

echo "Resource Quotas Enforced: $(kubectl get resourcequotas -n security-lab --no-headers | wc -l)"

echo "Pods Running: $(kubectl get pods -n security-lab --no-headers | grep Running | wc -l)"

