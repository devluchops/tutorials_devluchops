variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "The domain name for which to create cross-account access (e.g., devluchops.com)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "central_account_id" {
  description = "AWS Account ID where the central domain is hosted"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.central_account_id))
    error_message = "Central account ID must be a 12-digit number."
  }
}

variable "subdomain_account_id" {
  description = "AWS Account ID that will manage subdomains"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.subdomain_account_id))
    error_message = "Subdomain account ID must be a 12-digit number."
  }
}

variable "trusted_user_arn" {
  description = "ARN of the specific IAM user that can assume the cross-account role (optional, defaults to account root)"
  type        = string
  default     = null
  validation {
    condition     = var.trusted_user_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:user/[a-zA-Z0-9+=,.@_-]+$", var.trusted_user_arn))
    error_message = "Trusted user ARN must be a valid IAM user ARN or null."
  }
}

variable "role_name" {
  description = "Name of the cross-account IAM role"
  type        = string
  default     = "Route53CrossAccountRole"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9+=,.@_-]{0,63}$", var.role_name))
    error_message = "Role name must be valid IAM role name format."
  }
}

variable "role_max_session_duration" {
  description = "Maximum session duration for the cross-account role (in seconds)"
  type        = number
  default     = 3600
  validation {
    condition     = var.role_max_session_duration >= 3600 && var.role_max_session_duration <= 43200
    error_message = "Role max session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds."
  }
}

variable "external_id" {
  description = "External ID for additional security when assuming the role"
  type        = string
  default     = null
  validation {
    condition     = var.external_id == null || can(regex("^[a-zA-Z0-9+=,.@:/_-]{2,1224}$", var.external_id))
    error_message = "External ID must be between 2 and 1224 characters and contain only valid characters."
  }
}

variable "allowed_source_ips" {
  description = "List of allowed source IP addresses/CIDR blocks for assuming the role"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for ip in var.allowed_source_ips : can(cidrhost(ip, 0))
    ])
    error_message = "All allowed source IPs must be valid CIDR notation."
  }
}

variable "require_mfa" {
  description = "Whether to require MFA when assuming the cross-account role"
  type        = bool
  default     = false
}

variable "max_session_duration" {
  description = "Maximum allowed session duration (Unix timestamp)"
  type        = number
  default     = null
  validation {
    condition     = var.max_session_duration == null || var.max_session_duration > 0
    error_message = "Max session duration must be a positive number if specified."
  }
}

variable "allowed_subdomain_patterns" {
  description = "List of allowed subdomain patterns (wildcards supported)"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for pattern in var.allowed_subdomain_patterns : can(regex("^[a-zA-Z0-9.*-]+$", pattern))
    ])
    error_message = "Subdomain patterns must contain only alphanumeric characters, dots, asterisks, and hyphens."
  }
}

variable "allow_health_check_management" {
  description = "Whether to allow Route53 health check management"
  type        = bool
  default     = false
}

variable "allow_cloudwatch_integration" {
  description = "Whether to allow CloudWatch integration for health checks"
  type        = bool
  default     = false
}

variable "create_assume_role_policy" {
  description = "Whether to create a policy document for assuming the role (for reference)"
  type        = bool
  default     = true
}

variable "enable_audit_logging" {
  description = "Whether to enable CloudTrail audit logging for cross-account access"
  type        = bool
  default     = false
}

variable "audit_log_retention_days" {
  description = "Number of days to retain audit logs in S3"
  type        = number
  default     = 90
  validation {
    condition     = var.audit_log_retention_days > 0 && var.audit_log_retention_days <= 2555
    error_message = "Audit log retention days must be between 1 and 2555 days."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Project     = "cross-account-domain-management"
    Owner       = "devops-team"
    CostCenter  = "infrastructure"
    Component   = "iam-cross-account"
  }
}