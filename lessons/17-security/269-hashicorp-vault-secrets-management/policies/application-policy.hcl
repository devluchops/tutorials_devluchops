# Database Secrets Engine Policy
# Allows applications to generate dynamic database credentials

path "database/config/postgres-production" {
  capabilities = ["read"]
}

path "database/creds/readonly" {
  capabilities = ["read"]
}

path "database/creds/readwrite" {
  capabilities = ["read"]
}

# KV Secrets Engine Policy
# Application-specific secrets access

path "kv/data/applications/api-server/*" {
  capabilities = ["read", "list"]
}

path "kv/data/applications/frontend/*" {
  capabilities = ["read", "list"]
}

path "kv/metadata/applications/api-server/*" {
  capabilities = ["read", "list"]
}

path "kv/metadata/applications/frontend/*" {
  capabilities = ["read", "list"]
}

# AWS Secrets Engine Policy
# Dynamic AWS credentials for specific roles

path "aws/creds/s3-readonly" {
  capabilities = ["read"]
}

path "aws/creds/ec2-admin" {
  capabilities = ["read"]
}

# PKI Secrets Engine Policy
# Certificate generation for services

path "pki/issue/server-cert" {
  capabilities = ["create", "update"]
}

path "pki/cert/ca" {
  capabilities = ["read"]
}

# Transit Secrets Engine Policy
# Encryption as a Service

path "transit/encrypt/application-data" {
  capabilities = ["create", "update"]
}

path "transit/decrypt/application-data" {
  capabilities = ["create", "update"]
}

path "transit/datakey/plaintext/application-data" {
  capabilities = ["create", "update"]
}

# Identity Secrets Engine Policy
# Entity and group management

path "identity/entity/id/*" {
  capabilities = ["read"]
}

path "identity/group/id/*" {
  capabilities = ["read"]
}

# Auth Methods
# Allow token lookup and renewal

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

# Kubernetes Auth Method
path "auth/kubernetes/role/api-server" {
  capabilities = ["read"]
}

# LDAP Auth Method
path "auth/ldap/groups/*" {
  capabilities = ["read"]
}

# System endpoints for health checks
path "sys/health" {
  capabilities = ["read", "sudo"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}
