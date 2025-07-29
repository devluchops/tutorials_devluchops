# HashiCorp Vault Configuration
# Complete enterprise setup with high availability

# Storage backend configuration (Consul for HA)
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault/"
  
  # Consul configuration
  scheme                = "https"
  tls_ca_file          = "/opt/vault/tls/consul-ca.pem"
  tls_cert_file        = "/opt/vault/tls/consul-client.pem"
  tls_key_file         = "/opt/vault/tls/consul-client-key.pem"
  tls_min_version      = "tls12"
  
  # High availability
  ha_enabled            = "true"
  
  # Session TTL
  session_ttl          = "15s"
  lock_wait_time       = "15s"
  
  # Consistency
  consistency_mode     = "strong"
}

# HTTP listener configuration
listener "tcp" {
  address         = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  
  # TLS configuration
  tls_cert_file            = "/opt/vault/tls/vault-cert.pem"
  tls_key_file             = "/opt/vault/tls/vault-key.pem"
  tls_client_ca_file       = "/opt/vault/tls/vault-ca.pem"
  tls_min_version          = "tls12"
  tls_cipher_suites        = "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
  tls_prefer_server_cipher_suites = "true"
  tls_require_and_verify_client_cert = "false"
  
  # Security headers
  x_forwarded_for_authorized_addrs = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  x_forwarded_for_hop_skips        = "0"
  x_forwarded_for_reject_not_authorized = "true"
  x_forwarded_for_reject_not_present    = "true"
}

# Cluster configuration
cluster_name = "vault-production"
cluster_addr = "https://vault.company.com:8201"
api_addr     = "https://vault.company.com:8200"

# Cache configuration
cache_size = "32000"

# Default lease TTL
default_lease_ttl = "168h"  # 7 days
max_lease_ttl     = "720h"  # 30 days

# Logging
log_level = "INFO"
log_format = "json"
log_file = "/opt/vault/logs/vault.log"
log_rotate_duration = "24h"
log_rotate_max_files = 30

# Disable mlock (if running in containers)
disable_mlock = false

# Disable clustering (set to true for single node)
disable_clustering = false

# Plugin directory
plugin_directory = "/opt/vault/plugins"

# Raw storage endpoint (for debugging)
raw_storage_endpoint = false

# Introspection endpoint (disable in production)
introspection_endpoint = false

# Disable sealwrap (enterprise feature)
disable_sealwrap = false

# Enable UI
ui = true

# License path (enterprise)
license_path = "/opt/vault/license/vault.hclic"

# Telemetry configuration
telemetry {
  prometheus_retention_time = "24h"
  disable_hostname = false
  
  # StatsD configuration
  statsd_address = "127.0.0.1:8125"
  
  # Circonus configuration
  circonus_api_token = ""
  circonus_api_app = "vault"
  circonus_api_url = "https://api.circonus.com/v2"
  circonus_submission_interval = "10s"
  circonus_submission_url = ""
  circonus_check_id = ""
  circonus_check_force_metric_activation = false
  circonus_check_instance_id = ""
  circonus_check_search_tag = ""
  circonus_check_display_name = ""
  circonus_check_tags = ""
  circonus_broker_id = ""
  circonus_broker_select_tag = ""
}

# Entropy Augmentation (enterprise feature)
entropy "seal" {
  mode = "augmentation"
}

# Seal configuration (Auto-unseal with AWS KMS)
seal "awskms" {
  region     = "us-west-2"
  kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
  endpoint   = "https://kms.us-west-2.amazonaws.com"
}

# Service registration (for load balancers)
service_registration "consul" {
  address = "127.0.0.1:8500"
  scheme  = "https"
  
  # TLS configuration for Consul
  tls_ca_file   = "/opt/vault/tls/consul-ca.pem"
  tls_cert_file = "/opt/vault/tls/consul-client.pem"
  tls_key_file  = "/opt/vault/tls/consul-client-key.pem"
  
  # Service configuration
  service = "vault"
  service_tags = "production,active"
  service_address = ""
  
  # Check configuration
  check_timeout = "5s"
  
  # Namespace (Consul Enterprise)
  namespace = "vault"
}
