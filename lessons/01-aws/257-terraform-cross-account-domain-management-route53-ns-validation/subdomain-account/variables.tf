variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "subdomain_name" {
  description = "The subdomain name (e.g., app.devluchops.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.subdomain_name))
    error_message = "Subdomain name must be a valid domain format."
  }
}

variable "parent_domain" {
  description = "The parent domain name (e.g., devluchops.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.parent_domain))
    error_message = "Parent domain name must be a valid domain format."
  }
}

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

variable "central_account_id" {
  description = "AWS Account ID of the central account (where parent domain is hosted)"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.central_account_id))
    error_message = "Central account ID must be a 12-digit number."
  }
}

variable "cross_account_role_arn" {
  description = "ARN of the cross-account role in the central account"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:role/[a-zA-Z0-9+=,.@_-]+$", var.cross_account_role_arn))
    error_message = "Cross account role ARN must be a valid IAM role ARN."
  }
}

variable "external_id" {
  description = "External ID for additional security when assuming cross-account role"
  type        = string
  default     = null
}

variable "force_destroy_hosted_zone" {
  description = "Whether to force destroy the hosted zone even if it contains records"
  type        = bool
  default     = false
}

variable "ns_record_ttl" {
  description = "TTL for NS records in the parent domain"
  type        = number
  default     = 300
  validation {
    condition     = var.ns_record_ttl >= 30 && var.ns_record_ttl <= 86400
    error_message = "NS record TTL must be between 30 and 86400 seconds."
  }
}

variable "record_ttl" {
  description = "Default TTL for DNS records in the subdomain"
  type        = number
  default     = 300
  validation {
    condition     = var.record_ttl >= 30 && var.record_ttl <= 86400
    error_message = "Record TTL must be between 30 and 86400 seconds."
  }
}

variable "create_subdomain_a_record" {
  description = "Whether to create an A record for the subdomain"
  type        = bool
  default     = false
}

variable "subdomain_ip" {
  description = "IP address for the subdomain A record"
  type        = string
  default     = ""
  validation {
    condition = var.subdomain_ip == "" || can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.subdomain_ip))
    error_message = "Subdomain IP must be a valid IPv4 address or empty."
  }
}

variable "cname_records" {
  description = "Map of CNAME records to create (name -> target)"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for name, target in var.cname_records : can(regex("^[a-zA-Z0-9.-]+$", name)) && can(regex("^[a-zA-Z0-9.-]+$", target))
    ])
    error_message = "CNAME record names and targets must contain only alphanumeric characters, dots, and hyphens."
  }
}

variable "txt_records" {
  description = "Map of TXT records to create (name -> value)"
  type        = map(string)
  default     = {}
}

variable "a_records" {
  description = "Map of A records to create (name -> IP address)"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for name, ip in var.a_records : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", ip))
    ])
    error_message = "A record values must be valid IPv4 addresses."
  }
}

variable "aaaa_records" {
  description = "Map of AAAA records to create (name -> IPv6 address)"
  type        = map(string)
  default     = {}
  validation {
    condition = alltrue([
      for name, ip in var.aaaa_records : can(regex("^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::1$|^::$", ip))
    ])
    error_message = "AAAA record values must be valid IPv6 addresses."
  }
}

variable "mx_records" {
  description = "List of MX records for subdomain email configuration"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for record in var.mx_records : can(regex("^[0-9]+ [a-zA-Z0-9.-]+$", record))
    ])
    error_message = "MX records must be in format 'priority hostname' (e.g., '10 mail.example.com')."
  }
}

variable "enable_dns_logging" {
  description = "Whether to enable DNS query logging for the subdomain"
  type        = bool
  default     = false
}

variable "dns_log_retention_days" {
  description = "Number of days to retain DNS query logs"
  type        = number
  default     = 30
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.dns_log_retention_days)
    error_message = "DNS log retention days must be a valid CloudWatch log retention period."
  }
}

variable "create_health_check" {
  description = "Whether to create Route53 health check for the subdomain"
  type        = bool
  default     = false
}

variable "health_check_port" {
  description = "Port for health check"
  type        = number
  default     = 80
  validation {
    condition     = var.health_check_port > 0 && var.health_check_port <= 65535
    error_message = "Health check port must be between 1 and 65535."
  }
}

variable "health_check_type" {
  description = "Type of health check (HTTP, HTTPS, TCP)"
  type        = string
  default     = "HTTP"
  validation {
    condition     = contains(["HTTP", "HTTPS", "TCP"], var.health_check_type)
    error_message = "Health check type must be HTTP, HTTPS, or TCP."
  }
}

variable "health_check_path" {
  description = "Path for HTTP/HTTPS health checks"
  type        = string
  default     = "/"
}

variable "health_check_failure_threshold" {
  description = "Number of consecutive health check failures before considering endpoint unhealthy"
  type        = number
  default     = 3
  validation {
    condition     = var.health_check_failure_threshold >= 1 && var.health_check_failure_threshold <= 10
    error_message = "Health check failure threshold must be between 1 and 10."
  }
}

variable "health_check_interval" {
  description = "Health check interval in seconds (30 or 10)"
  type        = number
  default     = 30
  validation {
    condition     = contains([10, 30], var.health_check_interval)
    error_message = "Health check interval must be either 10 or 30 seconds."
  }
}

variable "health_check_alarm_actions" {
  description = "List of actions to execute when health check alarm triggers"
  type        = list(string)
  default     = []
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Project     = "cross-account-domain-management"
    Owner       = "devops-team"
    CostCenter  = "infrastructure"
  }
}