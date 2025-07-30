#!/bin/bash

# Vault Integration Script for Applications
VAULT_ADDR="http://vault:8200"
VAULT_ROLE="myapp-role"

# Function to get Vault token using Kubernetes auth
get_vault_token() {
    local jwt=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
    local response=\$(curl -s -X POST \\
        -H "Content-Type: application/json" \\
        -d "{\"jwt\":\"\$jwt\",\"role\":\"\$VAULT_ROLE\"}" \\
        \$VAULT_ADDR/v1/auth/kubernetes/login)
    
    echo \$response | jq -r .auth.client_token
}

# Function to get static secrets
get_static_secret() {
    local path=\$1
    local field=\$2
    local token=\$(get_vault_token)
    
    local response=\$(curl -s -H "X-Vault-Token: \$token" \\
        \$VAULT_ADDR/v1/secret/data/\$path)
    
    if [ -n "\$field" ]; then
        echo \$response | jq -r .data.data.\$field
    else
        echo \$response | jq .data.data
    fi
}

# Function to get dynamic database credentials
get_db_credentials() {
    local token=\$(get_vault_token)
    
    curl -s -H "X-Vault-Token: \$token" \\
        \$VAULT_ADDR/v1/database/creds/my-role | jq .data
}

# Example usage
echo "=== Static Secrets ==="
echo "Database password: \$(get_static_secret myapp/database password)"
echo "API key: \$(get_static_secret myapp/api stripe_key)"

echo ""
echo "=== Dynamic Database Credentials ==="
get_db_credentials