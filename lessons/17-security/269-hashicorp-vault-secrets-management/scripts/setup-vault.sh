#!/bin/bash

# Vault Setup and Configuration Script
# This script initializes and configures a production Vault cluster

set -euo pipefail

# Configuration
VAULT_ADDR="${VAULT_ADDR:-https://vault.company.com:8200}"
VAULT_CONFIG_DIR="${VAULT_CONFIG_DIR:-/opt/vault/config}"
VAULT_DATA_DIR="${VAULT_DATA_DIR:-/opt/vault/data}"
VAULT_LOG_DIR="${VAULT_LOG_DIR:-/opt/vault/logs}"
VAULT_TLS_DIR="${VAULT_TLS_DIR:-/opt/vault/tls}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Vault is installed
check_vault_installation() {
    log_info "Checking Vault installation..."
    
    if ! command -v vault &> /dev/null; then
        log_error "Vault is not installed. Please install Vault first."
        exit 1
    fi
    
    VAULT_VERSION=$(vault version | head -n1 | awk '{print $2}')
    log_info "Found Vault version: $VAULT_VERSION"
}

# Initialize Vault cluster
initialize_vault() {
    log_info "Initializing Vault cluster..."
    
    # Check if Vault is already initialized
    if vault status >/dev/null 2>&1; then
        log_warn "Vault is already initialized"
        return 0
    fi
    
    # Initialize with 5 key shares and 3 key threshold
    vault operator init \
        -key-shares=5 \
        -key-threshold=3 \
        -format=json > /tmp/vault-init.json
    
    log_info "Vault initialized successfully"
    log_warn "IMPORTANT: Save the unseal keys and root token from /tmp/vault-init.json"
    
    # Extract unseal keys and root token
    UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' /tmp/vault-init.json)
    UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' /tmp/vault-init.json)
    UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' /tmp/vault-init.json)
    ROOT_TOKEN=$(jq -r '.root_token' /tmp/vault-init.json)
    
    # Unseal Vault
    vault operator unseal "$UNSEAL_KEY_1"
    vault operator unseal "$UNSEAL_KEY_2"
    vault operator unseal "$UNSEAL_KEY_3"
    
    log_info "Vault unsealed successfully"
    
    # Export root token for initial configuration
    export VAULT_TOKEN="$ROOT_TOKEN"
}

# Configure Vault authentication methods
configure_auth_methods() {
    log_info "Configuring authentication methods..."
    
    # Enable Kubernetes authentication
    vault auth enable kubernetes
    
    # Configure Kubernetes auth
    vault write auth/kubernetes/config \
        token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
        kubernetes_host="https://kubernetes.default.svc.cluster.local" \
        kubernetes_ca_cert="$(cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt)"
    
    # Enable LDAP authentication
    vault auth enable ldap
    
    # Configure LDAP auth (example configuration)
    vault write auth/ldap/config \
        url="ldaps://ldap.company.com" \
        userdn="ou=users,dc=company,dc=com" \
        groupdn="ou=groups,dc=company,dc=com" \
        groupfilter="(&(objectClass=group)(member={{.UserDN}}))" \
        groupattr="cn" \
        upndomain="company.com" \
        certificate="$(cat $VAULT_TLS_DIR/ldap-ca.pem)" \
        insecure_tls=false \
        starttls=true
    
    # Enable AppRole authentication
    vault auth enable approle
    
    log_info "Authentication methods configured"
}

# Configure Vault secrets engines
configure_secrets_engines() {
    log_info "Configuring secrets engines..."
    
    # Enable KV v2 secrets engine
    vault secrets enable -version=2 kv
    
    # Enable Database secrets engine
    vault secrets enable database
    
    # Configure PostgreSQL database connection
    vault write database/config/postgres-production \
        plugin_name=postgresql-database-plugin \
        connection_url="postgresql://{{username}}:{{password}}@postgres.company.com:5432/production" \
        allowed_roles="readonly,readwrite" \
        username="vault_admin" \
        password="vault_admin_password"
    
    # Create database roles
    vault write database/roles/readonly \
        db_name=postgres-production \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h"
    
    vault write database/roles/readwrite \
        db_name=postgres-production \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1h" \
        max_ttl="24h"
    
    # Enable AWS secrets engine
    vault secrets enable aws
    
    # Configure AWS secrets engine
    vault write aws/config/root \
        access_key="$AWS_ACCESS_KEY_ID" \
        secret_key="$AWS_SECRET_ACCESS_KEY" \
        region="us-west-2"
    
    # Create AWS roles
    vault write aws/roles/s3-readonly \
        credential_type=iam_user \
        policy_document='{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "s3:GetObject",
                        "s3:ListBucket"
                    ],
                    "Resource": "*"
                }
            ]
        }'
    
    # Enable PKI secrets engine
    vault secrets enable pki
    vault secrets tune -max-lease-ttl=87600h pki
    
    # Generate root CA
    vault write pki/root/generate/internal \
        common_name="Company Internal CA" \
        ttl=87600h
    
    # Configure CA and CRL URLs
    vault write pki/config/urls \
        issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
        crl_distribution_points="$VAULT_ADDR/v1/pki/crl"
    
    # Create certificate role
    vault write pki/roles/server-cert \
        allowed_domains="company.com" \
        allow_subdomains=true \
        max_ttl="720h"
    
    # Enable Transit secrets engine
    vault secrets enable transit
    
    # Create encryption key
    vault write -f transit/keys/application-data
    
    log_info "Secrets engines configured"
}

# Configure Vault policies
configure_policies() {
    log_info "Configuring Vault policies..."
    
    # Application policy
    vault policy write application-policy - <<EOF
# Database access
path "database/creds/readonly" {
  capabilities = ["read"]
}

path "database/creds/readwrite" {
  capabilities = ["read"]
}

# KV secrets
path "kv/data/applications/*" {
  capabilities = ["read", "list"]
}

# AWS credentials
path "aws/creds/s3-readonly" {
  capabilities = ["read"]
}

# PKI certificates
path "pki/issue/server-cert" {
  capabilities = ["create", "update"]
}

# Transit encryption
path "transit/encrypt/application-data" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/application-data" {
  capabilities = ["create", "update"]
}
EOF
    
    # Admin policy
    vault policy write admin-policy - <<EOF
# Admin access to most paths
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Deny access to sensitive system paths
path "sys/raw/*" {
  capabilities = ["deny"]
}

path "sys/remount" {
  capabilities = ["deny"]
}
EOF
    
    # Developer policy
    vault policy write developer-policy - <<EOF
# Read-only access to KV secrets
path "kv/data/applications/dev/*" {
  capabilities = ["read", "list"]
}

# Database read-only access
path "database/creds/readonly" {
  capabilities = ["read"]
}

# Certificate generation
path "pki/issue/server-cert" {
  capabilities = ["create", "update"]
}
EOF
    
    log_info "Policies configured"
}

# Configure Kubernetes authentication roles
configure_k8s_roles() {
    log_info "Configuring Kubernetes authentication roles..."
    
    # API server role
    vault write auth/kubernetes/role/api-server \
        bound_service_account_names=api-server \
        bound_service_account_namespaces=production,staging \
        policies=application-policy \
        ttl=1h
    
    # Frontend role
    vault write auth/kubernetes/role/frontend \
        bound_service_account_names=frontend \
        bound_service_account_namespaces=production,staging \
        policies=application-policy \
        ttl=1h
    
    # Background jobs role
    vault write auth/kubernetes/role/background-jobs \
        bound_service_account_names=background-jobs \
        bound_service_account_namespaces=production,staging \
        policies=application-policy \
        ttl=2h
    
    log_info "Kubernetes roles configured"
}

# Configure AppRole authentication
configure_approle() {
    log_info "Configuring AppRole authentication..."
    
    # Application AppRole
    vault write auth/approle/role/api-server \
        token_policies="application-policy" \
        token_ttl=1h \
        token_max_ttl=4h \
        secret_id_ttl=10m \
        token_num_uses=10
    
    # Get Role ID and Secret ID
    ROLE_ID=$(vault read -field=role_id auth/approle/role/api-server/role-id)
    SECRET_ID=$(vault write -field=secret_id -f auth/approle/role/api-server/secret-id)
    
    log_info "AppRole configured"
    log_info "Role ID: $ROLE_ID"
    log_warn "Secret ID: $SECRET_ID (store securely)"
}

# Setup audit logging
configure_audit() {
    log_info "Configuring audit logging..."
    
    # Enable file audit
    vault audit enable file file_path="$VAULT_LOG_DIR/vault-audit.log"
    
    # Enable syslog audit (optional)
    # vault audit enable syslog tag="vault" facility="AUTH"
    
    log_info "Audit logging configured"
}

# Create sample secrets
create_sample_secrets() {
    log_info "Creating sample secrets..."
    
    # Application secrets
    vault kv put kv/applications/api-server/production \
        db_password="super_secure_password" \
        api_key="api_key_12345" \
        jwt_secret="jwt_secret_67890"
    
    vault kv put kv/applications/api-server/staging \
        db_password="staging_password" \
        api_key="staging_api_key" \
        jwt_secret="staging_jwt_secret"
    
    vault kv put kv/applications/frontend/production \
        api_endpoint="https://api.company.com" \
        cdn_url="https://cdn.company.com" \
        analytics_key="analytics_key_123"
    
    log_info "Sample secrets created"
}

# Health check function
health_check() {
    log_info "Performing health check..."
    
    # Check Vault status
    if vault status; then
        log_info "Vault is healthy and unsealed"
    else
        log_error "Vault health check failed"
        return 1
    fi
    
    # Test authentication
    if vault auth -method=userpass username=admin password=admin_password >/dev/null 2>&1; then
        log_info "Authentication test passed"
    else
        log_warn "Authentication test failed (this is expected if userpass is not configured)"
    fi
    
    # Test secrets access
    if vault kv get kv/applications/api-server/production >/dev/null 2>&1; then
        log_info "Secrets access test passed"
    else
        log_warn "Secrets access test failed"
    fi
}

# Backup Vault configuration
backup_vault() {
    log_info "Creating Vault backup..."
    
    BACKUP_DIR="/opt/vault/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup policies
    vault policy list | while read -r policy; do
        if [[ "$policy" != "default" ]] && [[ "$policy" != "root" ]]; then
            vault policy read "$policy" > "$BACKUP_DIR/policy_$policy.hcl"
        fi
    done
    
    # Backup auth methods configuration
    vault auth list -format=json > "$BACKUP_DIR/auth_methods.json"
    
    # Backup secrets engines configuration
    vault secrets list -format=json > "$BACKUP_DIR/secrets_engines.json"
    
    log_info "Backup created at $BACKUP_DIR"
}

# Main function
main() {
    log_info "Starting Vault setup and configuration..."
    
    # Check prerequisites
    check_vault_installation
    
    # Initialize and unseal Vault
    initialize_vault
    
    # Configure Vault
    configure_auth_methods
    configure_secrets_engines
    configure_policies
    configure_k8s_roles
    configure_approle
    configure_audit
    
    # Create sample data
    create_sample_secrets
    
    # Perform health check
    health_check
    
    # Create backup
    backup_vault
    
    log_info "Vault setup and configuration completed successfully!"
    log_warn "Remember to:"
    log_warn "1. Securely store the unseal keys and root token"
    log_warn "2. Revoke the root token after creating admin users"
    log_warn "3. Configure proper TLS certificates"
    log_warn "4. Set up monitoring and alerting"
    log_warn "5. Configure backup and disaster recovery"
}

# Run main function
main "$@"
