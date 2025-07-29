# HashiCorp Vault - Enterprise Secrets Management

Complete HashiCorp Vault tutorial for centralized secrets management, encryption, and authentication in enterprise environments.

## Why Vault?

### **Problem: Traditional Secrets Management**
```
❌ Common Problems:
├── Hardcoded secrets in code
├── Shared .env files
├── Credentials in environment variables
├── Passwords in databases
├── No automatic rotation
├── No centralized auditing
└── No granular access control
```

### **Solution: HashiCorp Vault**
```
✅ Vault Enterprise Solution:
├── 🔐 Dynamic secrets
├── 🔄 Automatic rotation  
├── 🛡️ Encryption as a service
├── 👥 Centralized authentication
├── 📊 Complete auditing
├── 🎯 Granular access control
└── 🔗 Native integration
```

## Core Concepts

### **1. Vault Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                    Vault Cluster                           │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Vault     │  │   Vault     │  │   Vault     │        │
│  │   Node 1    │  │   Node 2    │  │   Node 3    │        │
│  │  (Active)   │  │ (Standby)   │  │ (Standby)   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
├─────────────────────────────────────────────────────────────┤
│                  Storage Backend                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Consul    │  │  Raft       │  │  DynamoDB   │        │
│  │             │  │ Integrated  │  │             │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘

Applications/Users
       │
       ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Auth     │───▶│   Policy    │───▶│   Secrets   │
│  Methods    │    │   Engine    │    │   Engines   │
│ • LDAP      │    │ • ACL       │    │ • KV v2     │
│ • JWT       │    │ • Path      │    │ • Database  │
│ • AWS IAM   │    │ • Identity  │    │ • AWS       │
│ • K8s       │    │             │    │ • PKI       │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Installation & Setup

### **1. Development Server**
```bash
# Install Vault CLI
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault

# Start development server (NOT for production)
vault server -dev

# In another terminal
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='dev-only-token'

# Verify installation
vault status
```

### **2. Production Setup with Docker Compose**
```yaml
# docker-compose.yml
version: '3.8'

services:
  vault:
    image: hashicorp/vault:1.15
    container_name: vault
    ports:
      - "8200:8200"
    environment:
      VAULT_ADDR: 'http://0.0.0.0:8200'
      VAULT_API_ADDR: 'http://0.0.0.0:8200'
      VAULT_LOCAL_CONFIG: |
        {
          "backend": {
            "consul": {
              "address": "consul:8500",
              "path": "vault/"
            }
          },
          "listener": {
            "tcp": {
              "address": "0.0.0.0:8200",
              "tls_disable": 1
            }
          },
          "ui": true,
          "log_level": "INFO",
          "storage": {
            "raft": {
              "path": "/vault/data",
              "node_id": "vault-1"
            }
          },
          "cluster_addr": "http://vault:8201",
          "api_addr": "http://vault:8200"
        }
    cap_add:
      - IPC_LOCK
    volumes:
      - vault-data:/vault/data
      - vault-logs:/vault/logs
    command: vault server -config=/vault/config/local.json
    depends_on:
      - consul

  consul:
    image: hashicorp/consul:1.17
    container_name: consul
    ports:
      - "8500:8500"
    environment:
      CONSUL_BIND_INTERFACE: eth0
    volumes:
      - consul-data:/consul/data
    command: |
      consul agent -dev -client=0.0.0.0 -ui

  vault-init:
    image: hashicorp/vault:1.15
    container_name: vault-init
    environment:
      VAULT_ADDR: 'http://vault:8200'
    depends_on:
      - vault
    entrypoint: |
      sh -c "
        sleep 10
        if ! vault status > /dev/null 2>&1; then
          vault operator init -key-shares=5 -key-threshold=3 > /vault/data/init-keys.txt
          echo 'Vault initialized. Keys saved to /vault/data/init-keys.txt'
        else
          echo 'Vault already initialized'
        fi
      "
    volumes:
      - vault-data:/vault/data

volumes:
  vault-data:
  vault-logs:
  consul-data:

# Production configuration
# config/vault.hcl
ui = true
log_level = "INFO"

storage "raft" {
  path    = "/vault/data"
  node_id = "vault-1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/vault/certs/vault.crt"
  tls_key_file  = "/vault/certs/vault.key"
}

cluster_addr = "https://vault-1:8201"
api_addr = "https://vault-1:8200"

# Enable Prometheus metrics
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}
```

### **3. Kubernetes Deployment**
```yaml
# k8s/vault-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: vault

---
# k8s/vault-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault
  namespace: vault

---
# k8s/vault-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-config
  namespace: vault
data:
  vault.hcl: |
    ui = true
    log_level = "INFO"
    
    storage "kubernetes" {
      namespace = "vault"
      path = "/vault/data"
    }
    
    listener "tcp" {
      address = "0.0.0.0:8200"
      tls_disable = 1
    }
    
    service_registration "kubernetes" {}

---
# k8s/vault-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault
  namespace: vault
  labels:
    app: vault
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vault
  template:
    metadata:
      labels:
        app: vault
    spec:
      serviceAccountName: vault
      containers:
      - name: vault
        image: hashicorp/vault:1.15
        ports:
        - containerPort: 8200
          name: vault-port
          protocol: TCP
        - containerPort: 8201
          name: cluster-port
          protocol: TCP
        env:
        - name: VAULT_ADDR
          value: "http://localhost:8200"
        - name: VAULT_API_ADDR
          value: "http://localhost:8200"
        - name: VAULT_K8S_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: VAULT_K8S_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: config
          mountPath: /vault/config
        - name: data
          mountPath: /vault/data
        command:
        - vault
        - server
        - -config=/vault/config/vault.hcl
        securityContext:
          capabilities:
            add:
            - IPC_LOCK
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        readinessProbe:
          httpGet:
            path: /v1/sys/health?standbyok=true
            port: 8200
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /v1/sys/health?standbyok=true
            port: 8200
            scheme: HTTP
          initialDelaySeconds: 60
          periodSeconds: 30
      volumes:
      - name: config
        configMap:
          name: vault-config
      - name: data
        emptyDir: {}

---
# k8s/vault-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: vault
  namespace: vault
  labels:
    app: vault
spec:
  type: ClusterIP
  ports:
  - port: 8200
    targetPort: 8200
    name: vault-port
  - port: 8201
    targetPort: 8201
    name: cluster-port
  selector:
    app: vault

---
# k8s/vault-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: vault
  namespace: vault
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  tls:
  - hosts:
    - vault.example.com
    secretName: vault-tls
  rules:
  - host: vault.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: vault
            port:
              number: 8200
```

## Secrets Engines

### **1. Key-Value Store v2**
```bash
# Enable KV v2 secrets engine
vault secrets enable -path=secret kv-v2

# Write secrets
vault kv put secret/myapp/config \
  database_url="postgresql://user:pass@db:5432/myapp" \
  api_key="sk-1234567890abcdef" \
  debug=true

# Read secrets
vault kv get secret/myapp/config
vault kv get -field=database_url secret/myapp/config

# Versioned secrets
vault kv put secret/myapp/config \
  database_url="postgresql://user:newpass@db:5432/myapp" \
  api_key="sk-new1234567890abcdef"

# Get specific version
vault kv get -version=1 secret/myapp/config

# Delete latest version (soft delete)
vault kv delete secret/myapp/config

# Permanently delete all versions
vault kv destroy -versions=1,2 secret/myapp/config

# Metadata management
vault kv metadata put -max-versions=5 secret/myapp/config
vault kv metadata get secret/myapp/config
```

### **2. Dynamic Database Secrets**
```bash
# Enable database secrets engine
vault secrets enable database

# Configure database connection
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/myapp?sslmode=disable" \
  allowed_roles="readonly,readwrite" \
  username="vault" \
  password="vaultpassword"

# Create database role for read-only access
vault write database/roles/readonly \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
                      GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="1h" \
  max_ttl="24h"

# Create database role for read-write access  
vault write database/roles/readwrite \
  db_name=postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
                      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl="30m" \
  max_ttl="2h"

# Generate dynamic credentials
vault read database/creds/readonly
vault read database/creds/readwrite

# List active leases
vault list sys/leases/lookup/database/creds/readonly

# Revoke specific lease
vault lease revoke database/creds/readonly/lease_id

# Rotate root credentials
vault write -force database/rotate-root/postgresql
```

### **3. AWS Secrets Engine**
```bash
# Enable AWS secrets engine
vault secrets enable aws

# Configure AWS root credentials
vault write aws/config/root \
  access_key=AKIAIOSFODNN7EXAMPLE \
  secret_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \
  region=us-east-1

# Create role for EC2 instances
vault write aws/roles/ec2-readonly \
  credential_type=iam_user \
  policy_document=-<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create role for S3 access
vault write aws/roles/s3-admin \
  credential_type=iam_user \
  policy_arns=arn:aws:iam::aws:policy/AmazonS3FullAccess \
  default_sts_ttl=3600 \
  max_sts_ttl=7200

# Generate AWS credentials
vault read aws/creds/ec2-readonly
vault read aws/creds/s3-admin

# STS AssumeRole credentials
vault write aws/roles/deploy-role \
  credential_type=assumed_role \
  role_arns=arn:aws:iam::123456789012:role/MyRole \
  default_sts_ttl=3600

vault read aws/sts/deploy-role
```

### **4. PKI (Public Key Infrastructure)**
```bash
# Enable PKI secrets engine
vault secrets enable pki

# Configure CA and CRL URLs
vault write pki/config/urls \
  issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
  crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

# Generate root CA
vault write -field=certificate pki/root/generate/internal \
  common_name="My Company Root CA" \
  ttl=87600h > CA_cert.crt

# Create intermediate CA
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int

vault write -format=json pki_int/intermediate/generate/internal \
  common_name="My Company Intermediate Authority" \
  | jq -r '.data.csr' > pki_intermediate.csr

# Sign intermediate with root CA
vault write -format=json pki/root/sign-intermediate \
  csr=@pki_intermediate.csr \
  format=pem_bundle ttl="43800h" \
  | jq -r '.data.certificate' > intermediate.cert.pem

# Set intermediate certificate
vault write pki_int/intermediate/set-signed \
  certificate=@intermediate.cert.pem

# Create role for certificate generation
vault write pki_int/roles/example-dot-com \
  allowed_domains="example.com" \
  allow_subdomains=true \
  max_ttl="720h"

# Generate certificates
vault write pki_int/issue/example-dot-com \
  common_name="test.example.com" \
  ttl="24h"

# Revoke certificate
vault write pki_int/revoke \
  serial_number="39:dd:2e:90:b7:23:1f:8d:d3:7d:31:c5:1b:da:84:d0:5b:65:31:58"
```

## Authentication Methods

### **1. LDAP Authentication**
```bash
# Enable LDAP auth method
vault auth enable ldap

# Configure LDAP
vault write auth/ldap/config \
  url="ldap://ldap.company.com" \
  userdn="ou=Users,dc=company,dc=com" \
  userattr=uid \
  groupdn="ou=Groups,dc=company,dc=com" \
  groupfilter="(&(objectClass=groupOfNames)(member={{.UserDN}}))" \
  groupattr=cn \
  binddn="cn=vault,ou=Users,dc=company,dc=com" \
  bindpass="vaultpassword" \
  starttls=true \
  insecure_tls=false

# Map LDAP groups to Vault policies
vault write auth/ldap/groups/developers \
  policies=dev-policy

vault write auth/ldap/groups/admins \
  policies=admin-policy

vault write auth/ldap/groups/readonly \
  policies=readonly-policy

# Login with LDAP
vault login -method=ldap username=john.doe
```

### **2. Kubernetes Authentication**
```bash
# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create role for specific service account
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp \
  bound_service_account_namespaces=default \
  policies=myapp-policy \
  ttl=24h

# Application authentication from pod
vault write auth/kubernetes/login \
  role=myapp \
  jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
```

### **3. JWT Authentication**
```bash
# Enable JWT auth method
vault auth enable jwt

# Configure JWT auth with OIDC
vault write auth/jwt/config \
  oidc_discovery_url="https://auth.company.com" \
  oidc_client_id="vault" \
  oidc_client_secret="secret" \
  default_role="employee"

# Create role for JWT authentication
vault write auth/jwt/role/employee \
  role_type="jwt" \
  bound_audiences="vault" \
  bound_claims='{"department":"engineering"}' \
  user_claim="email" \
  groups_claim="groups" \
  policies="employee-policy" \
  ttl="1h"

# Login with JWT
vault login -method=jwt role=employee jwt="eyJhbGciOiJSUzI1NiIs..."
```

## Policies and Access Control

### **1. Policy Language**
```hcl
# policies/dev-policy.hcl
# Developer policy for application secrets

# Allow read/write access to development secrets
path "secret/data/dev/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Allow read access to development configurations
path "secret/data/config/dev/*" {
  capabilities = ["read", "list"]
}

# Allow access to database credentials for dev environment
path "database/creds/dev-readonly" {
  capabilities = ["read"]
}

# Allow users to change their own password
path "auth/userpass/users/{{identity.entity.name}}/password" {
  capabilities = ["update"]
}

# Allow token self-renewal
path "auth/token/renew-self" {
  capabilities = ["update"]
}

# Allow looking up own token
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Deny access to production secrets
path "secret/data/prod/*" {
  capabilities = ["deny"]
}

# policies/admin-policy.hcl
# Administrator policy with broad access

# Full access to all secret paths
path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage auth methods
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Manage policies
path "sys/policies/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage secret engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# View system status
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# Manage leases
path "sys/leases/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Advanced policy with templating
# policies/app-policy.hcl
path "secret/data/apps/{{identity.entity.metadata.app_name}}/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Time-based access
path "secret/data/temp/*" {
  capabilities = ["create", "read", "update", "delete"]
  allowed_parameters = {
    "ttl" = ["1h", "2h", "4h"]
  }
}

# IP-based restrictions
path "secret/data/sensitive/*" {
  capabilities = ["read"]
  allowed_client_cidrs = ["10.0.0.0/8", "192.168.1.0/24"]
}
```

### **2. Policy Management**
```bash
# Create policies
vault policy write dev-policy policies/dev-policy.hcl
vault policy write admin-policy policies/admin-policy.hcl
vault policy write app-policy policies/app-policy.hcl

# List policies
vault policy list

# Read policy
vault policy read dev-policy

# Delete policy
vault policy delete old-policy

# Test policy (requires Vault Enterprise)
vault policy test dev-policy <<< "secret/data/dev/myapp"
```

## Advanced Features

### **1. Vault Agent for Auto-Authentication**
```hcl
# vault-agent.hcl
pid_file = "./pidfile"

vault {
  address = "http://vault.company.com:8200"
}

auto_auth {
  method "kubernetes" {
    mount_path = "auth/kubernetes"
    config = {
      role = "myapp"
    }
  }

  sink "file" {
    config = {
      path = "/tmp/vault-token"
    }
  }
}

cache {
  use_auto_auth_token = true
}

listener "tcp" {
  address = "127.0.0.1:8100"
  tls_disable = true
}

template {
  source      = "/etc/vault/templates/database.tpl"
  destination = "/etc/myapp/database.conf"
  perms       = 0640
  command     = "systemctl reload myapp"
}

template {
  source      = "/etc/vault/templates/api-keys.tpl"
  destination = "/etc/myapp/api-keys.json"
  perms       = 0600
}
```

```bash
# Start Vault Agent
vault agent -config=vault-agent.hcl
```

### **2. Vault Operator for Kubernetes**
```yaml
# vault-operator/vault-cluster.yaml
apiVersion: vault.security.coreos.com/v1alpha1
kind: VaultService
metadata:
  name: vault-cluster
  namespace: vault
spec:
  nodes: 3
  version: "1.15.0"
  
  baseImage: vault
  
  pod:
    resources:
      vault:
        limits:
          cpu: 500m
          memory: 512Mi
        requests:
          cpu: 100m
          memory: 128Mi
    
    securityContext:
      runAsNonRoot: true
      runAsUser: 65534
      fsGroup: 65534
  
  # TLS configuration
  TLS:
    static:
      serverSecret: vault-server-tls
      clientSecret: vault-client-tls
  
  # Storage backend
  backend:
    consul:
      address: "consul:8500"
      path: "vault/"
      scheme: "http"

---
apiVersion: v1
kind: Secret
metadata:
  name: vault-server-tls
  namespace: vault
type: kubernetes.io/tls
data:
  tls.crt: # base64 encoded certificate
  tls.key: # base64 encoded private key

---
apiVersion: v1
kind: Secret
metadata:
  name: vault-client-tls
  namespace: vault
type: kubernetes.io/tls
data:
  tls.crt: # base64 encoded certificate
  tls.key: # base64 encoded private key
```

### **3. Vault CSI Driver**
```yaml
# vault-csi/secret-provider-class.yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets
  namespace: default
spec:
  provider: vault
  parameters:
    vaultAddress: "http://vault.vault:8200"
    roleName: "myapp"
    objects: |
      - objectName: "database-password"
        secretPath: "secret/data/myapp/config"
        secretKey: "database_password"
      - objectName: "api-key"
        secretPath: "secret/data/myapp/config"
        secretKey: "api_key"
  secretObjects:
  - secretName: app-secrets
    type: Opaque
    data:
    - objectName: "database-password"
      key: "database_password"
    - objectName: "api-key"
      key: "api_key"

---
# vault-csi/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      serviceAccountName: myapp
      containers:
      - name: myapp
        image: myapp:latest
        env:
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database_password
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: api_key
        volumeMounts:
        - name: secrets-store
          mountPath: "/mnt/secrets"
          readOnly: true
      volumes:
      - name: secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "app-secrets"
```

## Application Integration

### **1. Python Application**
```python
# app.py
import hvac
import os
import logging
from typing import Dict, Any, Optional
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class VaultManager:
    def __init__(self, vault_addr: str, auth_method: str = "kubernetes"):
        """
        Initialize Vault client with auto-authentication
        """
        self.client = hvac.Client(url=vault_addr)
        self.auth_method = auth_method
        self._authenticate()
        
    def _authenticate(self):
        """Authenticate with Vault using specified method"""
        try:
            if self.auth_method == "kubernetes":
                self._auth_kubernetes()
            elif self.auth_method == "userpass":
                self._auth_userpass()
            elif self.auth_method == "token":
                self._auth_token()
            else:
                raise ValueError(f"Unsupported auth method: {self.auth_method}")
                
            logger.info("Successfully authenticated with Vault")
        except Exception as e:
            logger.error(f"Failed to authenticate with Vault: {e}")
            raise
    
    def _auth_kubernetes(self):
        """Authenticate using Kubernetes service account"""
        with open('/var/run/secrets/kubernetes.io/serviceaccount/token', 'r') as f:
            jwt = f.read()
        
        response = self.client.auth.kubernetes.login(
            role=os.getenv('VAULT_ROLE', 'myapp'),
            jwt=jwt
        )
        self.client.token = response['auth']['client_token']
        
    def _auth_userpass(self):
        """Authenticate using username/password"""
        username = os.getenv('VAULT_USERNAME')
        password = os.getenv('VAULT_PASSWORD')
        
        response = self.client.auth.userpass.login(
            username=username,
            password=password
        )
        self.client.token = response['auth']['client_token']
        
    def _auth_token(self):
        """Authenticate using Vault token"""
        token = os.getenv('VAULT_TOKEN')
        self.client.token = token
        
    def get_secret(self, path: str, mount_point: str = "secret") -> Dict[str, Any]:
        """Get secret from KV v2 store"""
        try:
            response = self.client.secrets.kv.v2.read_secret_version(
                path=path,
                mount_point=mount_point
            )
            return response['data']['data']
        except Exception as e:
            logger.error(f"Failed to get secret {path}: {e}")
            raise
    
    def get_database_credentials(self, role: str) -> Dict[str, str]:
        """Get dynamic database credentials"""
        try:
            response = self.client.secrets.database.generate_credentials(
                name=role
            )
            return {
                'username': response['data']['username'],
                'password': response['data']['password'],
                'lease_id': response['lease_id'],
                'lease_duration': response['lease_duration']
            }
        except Exception as e:
            logger.error(f"Failed to get database credentials: {e}")
            raise
    
    def get_aws_credentials(self, role: str) -> Dict[str, str]:
        """Get dynamic AWS credentials"""
        try:
            response = self.client.secrets.aws.generate_credentials(
                name=role
            )
            return {
                'access_key': response['data']['access_key'],
                'secret_key': response['data']['secret_key'],
                'security_token': response['data'].get('security_token'),
                'lease_id': response['lease_id']
            }
        except Exception as e:
            logger.error(f"Failed to get AWS credentials: {e}")
            raise
    
    def renew_lease(self, lease_id: str, increment: Optional[int] = None):
        """Renew a lease"""
        try:
            self.client.sys.renew_lease(
                lease_id=lease_id,
                increment=increment
            )
            logger.info(f"Renewed lease {lease_id}")
        except Exception as e:
            logger.error(f"Failed to renew lease {lease_id}: {e}")
    
    def revoke_lease(self, lease_id: str):
        """Revoke a lease"""
        try:
            self.client.sys.revoke_lease(lease_id)
            logger.info(f"Revoked lease {lease_id}")
        except Exception as e:
            logger.error(f"Failed to revoke lease {lease_id}: {e}")

class DatabaseManager:
    def __init__(self, vault_manager: VaultManager):
        self.vault = vault_manager
        self.db_creds = None
        self.lease_id = None
        
    def get_connection(self):
        """Get database connection with auto-renewal"""
        if not self.db_creds:
            self._refresh_credentials()
        
        # Check if credentials are close to expiring
        # In production, you'd track the lease expiration time
        
        import psycopg2
        return psycopg2.connect(
            host=os.getenv('DB_HOST'),
            port=os.getenv('DB_PORT', 5432),
            database=os.getenv('DB_NAME'),
            user=self.db_creds['username'],
            password=self.db_creds['password']
        )
    
    def _refresh_credentials(self):
        """Refresh database credentials"""
        logger.info("Refreshing database credentials")
        
        # Revoke old credentials
        if self.lease_id:
            self.vault.revoke_lease(self.lease_id)
        
        # Get new credentials
        creds = self.vault.get_database_credentials('myapp-readonly')
        self.db_creds = creds
        self.lease_id = creds['lease_id']
        
        logger.info("Database credentials refreshed")

# Application code
def main():
    vault_addr = os.getenv('VAULT_ADDR', 'http://vault:8200')
    vault = VaultManager(vault_addr)
    
    # Get application configuration
    config = vault.get_secret('myapp/config')
    
    # Get database connection
    db_manager = DatabaseManager(vault)
    conn = db_manager.get_connection()
    
    # Get AWS credentials for S3 access
    aws_creds = vault.get_aws_credentials('s3-readonly')
    
    # Use credentials in your application
    logger.info("Application started with secure credentials")
    
    # Simulate application work
    time.sleep(60)

if __name__ == "__main__":
    main()
```

### **2. Go Application**
```go
// main.go
package main

import (
    "context"
    "encoding/json"
    "fmt"
    "log"
    "os"
    "time"

    "github.com/hashicorp/vault/api"
    "github.com/hashicorp/vault/api/auth/kubernetes"
)

type VaultManager struct {
    client *api.Client
}

type DatabaseCredentials struct {
    Username     string `json:"username"`
    Password     string `json:"password"`
    LeaseID      string `json:"lease_id"`
    LeaseDuration int   `json:"lease_duration"`
}

func NewVaultManager(vaultAddr string) (*VaultManager, error) {
    config := api.DefaultConfig()
    config.Address = vaultAddr
    
    client, err := api.NewClient(config)
    if err != nil {
        return nil, fmt.Errorf("unable to initialize Vault client: %w", err)
    }
    
    vm := &VaultManager{client: client}
    
    // Authenticate
    if err := vm.authenticate(); err != nil {
        return nil, fmt.Errorf("authentication failed: %w", err)
    }
    
    return vm, nil
}

func (vm *VaultManager) authenticate() error {
    // Kubernetes authentication
    k8sAuth, err := kubernetes.NewKubernetesAuth("myapp")
    if err != nil {
        return fmt.Errorf("unable to initialize Kubernetes auth method: %w", err)
    }
    
    authInfo, err := vm.client.Auth().Login(context.Background(), k8sAuth)
    if err != nil {
        return fmt.Errorf("unable to log in with Kubernetes auth: %w", err)
    }
    
    if authInfo == nil {
        return fmt.Errorf("no auth info was returned after login")
    }
    
    log.Println("Successfully authenticated with Vault")
    return nil
}

func (vm *VaultManager) GetSecret(secretPath string) (map[string]interface{}, error) {
    secret, err := vm.client.KVv2("secret").Get(context.Background(), secretPath)
    if err != nil {
        return nil, fmt.Errorf("unable to read secret: %w", err)
    }
    
    return secret.Data, nil
}

func (vm *VaultManager) GetDatabaseCredentials(role string) (*DatabaseCredentials, error) {
    secret, err := vm.client.Logical().Read(fmt.Sprintf("database/creds/%s", role))
    if err != nil {
        return nil, fmt.Errorf("unable to read database credentials: %w", err)
    }
    
    if secret == nil {
        return nil, fmt.Errorf("no credentials returned")
    }
    
    creds := &DatabaseCredentials{
        Username:      secret.Data["username"].(string),
        Password:      secret.Data["password"].(string),
        LeaseID:       secret.LeaseID,
        LeaseDuration: secret.LeaseDuration,
    }
    
    return creds, nil
}

func (vm *VaultManager) RenewLease(leaseID string, increment int) error {
    _, err := vm.client.Sys().Renew(leaseID, increment)
    if err != nil {
        return fmt.Errorf("unable to renew lease: %w", err)
    }
    
    log.Printf("Successfully renewed lease %s", leaseID)
    return nil
}

func (vm *VaultManager) RevokeLease(leaseID string) error {
    err := vm.client.Sys().Revoke(leaseID)
    if err != nil {
        return fmt.Errorf("unable to revoke lease: %w", err)
    }
    
    log.Printf("Successfully revoked lease %s", leaseID)
    return nil
}

// Background lease renewal
func (vm *VaultManager) StartLeaseRenewal(creds *DatabaseCredentials) {
    go func() {
        ticker := time.NewTicker(time.Duration(creds.LeaseDuration/2) * time.Second)
        defer ticker.Stop()
        
        for {
            select {
            case <-ticker.C:
                if err := vm.RenewLease(creds.LeaseID, 0); err != nil {
                    log.Printf("Failed to renew lease: %v", err)
                }
            }
        }
    }()
}

func main() {
    vaultAddr := os.Getenv("VAULT_ADDR")
    if vaultAddr == "" {
        vaultAddr = "http://vault:8200"
    }
    
    vm, err := NewVaultManager(vaultAddr)
    if err != nil {
        log.Fatalf("Failed to initialize Vault manager: %v", err)
    }
    
    // Get application configuration
    config, err := vm.GetSecret("myapp/config")
    if err != nil {
        log.Fatalf("Failed to get configuration: %v", err)
    }
    
    log.Printf("Loaded configuration: %v", config)
    
    // Get database credentials
    dbCreds, err := vm.GetDatabaseCredentials("myapp-readonly")
    if err != nil {
        log.Fatalf("Failed to get database credentials: %v", err)
    }
    
    log.Printf("Got database credentials for user: %s", dbCreds.Username)
    
    // Start background lease renewal
    vm.StartLeaseRenewal(dbCreds)
    
    // Your application logic here
    log.Println("Application running with secure credentials...")
    
    // Keep application running
    select {}
}
```

## Monitoring and Observability

### **1. Prometheus Metrics**
```yaml
# monitoring/vault-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vault
  namespace: vault
  labels:
    app: vault
spec:
  selector:
    matchLabels:
      app: vault
  endpoints:
  - port: vault-port
    path: /v1/sys/metrics
    params:
      format: ['prometheus']
    interval: 30s
    scrapeTimeout: 10s
    bearerTokenSecret:
      name: vault-prometheus-token
      key: token

---
# monitoring/vault-prometheusrule.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: vault-alerts
  namespace: vault
spec:
  groups:
  - name: vault.rules
    rules:
    - alert: VaultDown
      expr: up{job="vault"} == 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: "Vault is down"
        description: "Vault has been down for more than 1 minute"
    
    - alert: VaultSealed
      expr: vault_core_unsealed == 0
      for: 0m
      labels:
        severity: critical
      annotations:
        summary: "Vault is sealed"
        description: "Vault instance is sealed and unavailable"
    
    - alert: VaultHighRequestLatency
      expr: vault_core_handle_request{quantile="0.99"} > 1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High Vault request latency"
        description: "99th percentile latency is {{ $value }}s"
    
    - alert: VaultLeadershipChange
      expr: increase(vault_core_leadership_lost_count[1h]) > 0
      for: 0m
      labels:
        severity: warning
      annotations:
        summary: "Vault leadership changed"
        description: "Vault cluster leadership has changed"
```

### **2. Audit Logging**
```bash
# Enable file audit device
vault audit enable file file_path=/vault/logs/audit.log

# Enable syslog audit device
vault audit enable syslog tag="vault" facility="auth"

# Enable socket audit device
vault audit enable socket address="audit.company.com:9090" socket_type="tcp"

# List audit devices
vault audit list

# Sample audit log entry
{
  "time": "2023-01-15T10:30:45.123456789Z",
  "type": "request",
  "auth": {
    "client_token": "hmac-sha256:abcd1234...",
    "accessor": "hmac-sha256:efgh5678...",
    "display_name": "kubernetes-default-myapp",
    "policies": ["default", "myapp-policy"],
    "token_policies": ["default", "myapp-policy"],
    "metadata": {
      "role": "myapp",
      "service_account_name": "myapp",
      "service_account_namespace": "default"
    }
  },
  "request": {
    "id": "12345678-1234-1234-1234-123456789012",
    "operation": "read",
    "mount_type": "kv",
    "client_token": "hmac-sha256:abcd1234...",
    "client_token_accessor": "hmac-sha256:efgh5678...",
    "namespace": {
      "id": "root"
    },
    "path": "secret/data/myapp/config",
    "data": null,
    "remote_address": "10.0.1.100"
  },
  "response": {
    "mount_type": "kv",
    "data": {
      "data": "hmac-sha256:sensitive-data-hash",
      "metadata": {
        "created_time": "2023-01-15T09:00:00.123456789Z",
        "deletion_time": "",
        "destroyed": false,
        "version": 1
      }
    }
  }
}
```

## Security Hardening

### **1. Production Configuration**
```hcl
# vault-production.hcl
cluster_name = "vault-prod"

# Storage configuration
storage "consul" {
  address = "consul.service.consul:8500"
  path    = "vault/"
  
  # Consul ACL token
  token = "vault-consul-token"
  
  # TLS configuration
  scheme = "https"
  tls_ca_file = "/vault/tls/consul-ca.pem"
  tls_cert_file = "/vault/tls/consul-client.pem"
  tls_key_file = "/vault/tls/consul-client-key.pem"
  tls_min_version = "tls12"
}

# HA configuration
ha_storage "consul" {
  address = "consul.service.consul:8500"
  path    = "vault/"
  token = "vault-consul-token"
  scheme = "https"
  tls_ca_file = "/vault/tls/consul-ca.pem"
  tls_cert_file = "/vault/tls/consul-client.pem"
  tls_key_file = "/vault/tls/consul-client-key.pem"
}

# Listener configuration
listener "tcp" {
  address       = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  
  # TLS configuration
  tls_cert_file = "/vault/tls/vault.pem"
  tls_key_file  = "/vault/tls/vault-key.pem"
  tls_client_ca_file = "/vault/tls/ca.pem"
  
  # Security headers
  tls_min_version = "tls12"
  tls_cipher_suites = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
  
  # Request size limits
  tls_require_and_verify_client_cert = false
  tls_disable_client_certs = false
}

# Cluster configuration
cluster_addr = "https://vault-1.vault.svc.cluster.local:8201"
api_addr = "https://vault-1.vault.svc.cluster.local:8200"

# Seal configuration (auto-unseal)
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
}

# UI
ui = true

# Logging
log_level = "INFO"
log_format = "json"

# Disable memory lock (if running in container)
disable_mlock = true

# Raw storage endpoint disable
raw_storage_endpoint = false

# Disable performance standby
disable_performance_standby = false

# Enterprise features
license_path = "/vault/license/vault.hclic"

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
  
  # StatsD
  statsd_address = "statsd.monitoring.svc.cluster.local:8125"
  
  # Datadog
  dogstatsd_addr = "datadog-agent.monitoring.svc.cluster.local:8125"
  dogstatsd_tags = ["vault_cluster:prod", "environment:production"]
}

# Entropy Augmentation
entropy "seal" {
  mode = "augmentation"
}
```

### **2. Security Policies**
```bash
#!/bin/bash
# scripts/vault-security-hardening.sh

set -e

echo "🔒 Vault Security Hardening Script"

# 1. Disable unused auth methods
echo "Disabling unused auth methods..."
vault auth disable userpass 2>/dev/null || true
vault auth disable github 2>/dev/null || true
vault auth disable okta 2>/dev/null || true

# 2. Enable audit logging
echo "Enabling audit logging..."
vault audit enable file file_path=/vault/logs/audit.log
vault audit enable syslog tag="vault" facility="local0"

# 3. Configure password policies
echo "Setting up password policies..."
vault write sys/policies/password/default << EOF
length = 20
rule "charset" {
  charset = "abcdefghijklmnopqrstuvwxyz"
  min-chars = 1
}
rule "charset" {
  charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  min-chars = 1
}
rule "charset" {
  charset = "0123456789"
  min-chars = 1
}
rule "charset" {
  charset = "!@#$%^&*"
  min-chars = 1
}
EOF

# 4. Set up secret engine security
echo "Configuring secrets engines..."

# KV v2 with CAS required
vault secrets enable -path=secure-kv -options=cas_required=true kv-v2

# Database with limited connection lifetime
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/myapp?sslmode=require" \
  allowed_roles="readonly,readwrite" \
  username="vault" \
  password="$DB_VAULT_PASSWORD" \
  max_open_connections=5 \
  max_connection_lifetime=300s

# 5. Configure auth method tuning
echo "Tuning authentication methods..."

# Kubernetes auth with strict settings
vault write auth/kubernetes/config \
  token_reviewer_jwt="$K8S_TOKEN" \
  kubernetes_host="$K8S_HOST" \
  kubernetes_ca_cert="$K8S_CA_CERT" \
  disable_iss_validation=false \
  disable_local_ca_jwt=false

# 6. Set up monitoring
echo "Configuring monitoring..."
vault write sys/config/auditing/request-headers/X-Forwarded-For value=true
vault write sys/config/auditing/request-headers/X-Real-IP value=true

# 7. Enable CORS if needed
vault write sys/config/cors \
  enabled=true \
  allowed_origins="https://vault.company.com" \
  allowed_headers="*"

# 8. Configure UI settings
vault write sys/config/ui \
  enabled=true \
  default_headers='{"Content-Security-Policy": ["default-src '\''self'\''"]}'

echo "✅ Vault security hardening completed"
```

## Best Practices

### **1. Secret Management Patterns**
```bash
# Naming conventions
secret/data/environment/application/component/secret-name
secret/data/prod/myapp/database/credentials
secret/data/dev/myapp/api/external-key

# Versioning strategy
vault kv put secret/myapp/config @config-v1.json
vault kv put secret/myapp/config @config-v2.json

# Metadata usage
vault kv metadata put secret/myapp/config \
  max-versions=10 \
  delete-version-after=720h

# Secret rotation
vault kv put secret/myapp/config \
  api_key="new-key" \
  rotation_date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

### **2. Operational Procedures**
```bash
#!/bin/bash
# scripts/vault-operations.sh

# Health checks
check_vault_health() {
  echo "Checking Vault health..."
  vault status
  vault auth list
  vault secrets list
  vault policy list
}

# Backup procedures
backup_vault() {
  echo "Creating Vault backup..."
  
  # Snapshot (Consul backend)
  consul snapshot save backup-$(date +%Y%m%d-%H%M%S).snap
  
  # Export policies
  mkdir -p backup/policies
  for policy in $(vault policy list); do
    vault policy read "$policy" > "backup/policies/${policy}.hcl"
  done
  
  # Export auth methods configuration
  vault auth list -format=json > backup/auth-methods.json
  
  # Export secrets engines configuration
  vault secrets list -format=json > backup/secrets-engines.json
}

# Seal/Unseal procedures
emergency_seal() {
  echo "Emergency sealing Vault..."
  vault operator seal
}

unseal_vault() {
  echo "Unsealing Vault..."
  vault operator unseal "$UNSEAL_KEY_1"
  vault operator unseal "$UNSEAL_KEY_2"
  vault operator unseal "$UNSEAL_KEY_3"
}

# Key rotation
rotate_encryption_key() {
  echo "Rotating encryption key..."
  vault operator key-status
  vault operator rotate
  vault operator key-status
}

# Rekey operation
rekey_vault() {
  echo "Rekeying Vault..."
  vault operator rekey -init -key-shares=5 -key-threshold=3
  
  # Follow prompts to provide unseal keys
  # Then provide new unseal keys to complete the process
}
```

## Useful Links

- [Vault Documentation](https://www.vaultproject.io/docs)
- [Vault API](https://www.vaultproject.io/api-docs)
- [Vault Helm Chart](https://github.com/hashicorp/vault-helm)
- [Vault CSI Provider](https://github.com/hashicorp/vault-csi-provider)
- [Vault Community](https://discuss.hashicorp.com/c/vault)
- [Vault Tutorials](https://learn.hashicorp.com/vault)
