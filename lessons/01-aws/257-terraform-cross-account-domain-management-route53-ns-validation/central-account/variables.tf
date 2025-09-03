variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "The main domain name (e.g., devluchops.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  default     = "production"
}

variable "subdomain_account_id" {
  description = "AWS Account ID that will manage subdomains"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.subdomain_account_id))
    error_message = "Account ID must be a 12-digit number."
  }
}

variable "force_destroy_hosted_zone" {
  description = "Whether to force destroy the hosted zone even if it contains records"
  type        = bool
  default     = false
}

variable "create_verification_record" {
  description = "Whether to create a TXT record for domain verification"
  type        = bool
  default     = true
}

variable "create_main_a_record" {
  description = "Whether to create an A record for the main domain"
  type        = bool
  default     = false
}

variable "main_domain_ip" {
  description = "IP address for the main domain A record"
  type        = string
  default     = ""
  validation {
    condition = var.main_domain_ip == "" || can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.main_domain_ip))
    error_message = "Main domain IP must be a valid IPv4 address or empty."
  }
}

variable "create_www_record" {
  description = "Whether to create a CNAME record for www subdomain"
  type        = bool
  default     = true
}

variable "create_mx_records" {
  description = "Whether to create MX records for email"
  type        = bool
  default     = false
}

variable "mx_records" {
  description = "List of MX records for email configuration"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for record in var.mx_records : can(regex("^[0-9]+ [a-zA-Z0-9.-]+$", record))
    ])
    error_message = "MX records must be in format 'priority hostname' (e.g., '10 mail.example.com')."
  }
}

variable "create_spf_record" {
  description = "Whether to create SPF record for email security"
  type        = bool
  default     = false
}

variable "spf_record" {
  description = "SPF record value for email security"
  type        = string
  default     = "v=spf1 -all"
}

variable "enable_dns_logging" {
  description = "Whether to enable DNS query logging"
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
  description = "Whether to create Route53 health check for the main domain"
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