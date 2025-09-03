terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

# Data source to get current AWS account ID (central account)
data "aws_caller_identity" "current" {}

# Get the hosted zone for the domain to restrict permissions
data "aws_route53_zone" "main_domain" {
  name         = var.domain_name
  private_zone = false
}

# IAM policy document for the trust relationship
data "aws_iam_policy_document" "cross_account_trust_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type = "AWS"
      identifiers = [
        var.trusted_user_arn != null ? var.trusted_user_arn : "arn:aws:iam::${var.subdomain_account_id}:root"
      ]
    }
    
    actions = [
      "sts:AssumeRole"
    ]
    
    # Optional: Add external ID for additional security
    dynamic "condition" {
      for_each = var.external_id != null ? [1] : []
      content {
        test     = "StringEquals"
        variable = "sts:ExternalId"
        values   = [var.external_id]
      }
    }
    
    # Optional: Add source IP restriction
    dynamic "condition" {
      for_each = length(var.allowed_source_ips) > 0 ? [1] : []
      content {
        test     = "IpAddress"
        variable = "aws:SourceIp"
        values   = var.allowed_source_ips
      }
    }
    
    # Optional: Require MFA
    dynamic "condition" {
      for_each = var.require_mfa ? [1] : []
      content {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }
    
    # Optional: Restrict session duration
    dynamic "condition" {
      for_each = var.max_session_duration != null ? [1] : []
      content {
        test     = "NumericLessThan"
        variable = "aws:TokenIssueTime"
        values   = [tostring(var.max_session_duration)]
      }
    }
  }
}

# IAM policy document for Route53 permissions
data "aws_iam_policy_document" "route53_cross_account_policy" {
  statement {
    sid    = "AllowRoute53ListOperations"
    effect = "Allow"
    
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:GetHostedZone",
      "route53:GetChange"
    ]
    
    resources = ["*"]
  }
  
  statement {
    sid    = "AllowRoute53RecordManagement"
    effect = "Allow"
    
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:CreateHostedZone",
      "route53:DeleteHostedZone"
    ]
    
    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.main_domain.zone_id}"
    ]
    
    # Restrict to specific record types
    condition {
      test     = "StringEquals"
      variable = "route53:ChangeAction"
      values   = ["CREATE", "DELETE", "UPSERT"]
    }
  }
  
  # Allow creating NS records for subdomains
  statement {
    sid    = "AllowNSRecordManagement"
    effect = "Allow"
    
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    
    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.main_domain.zone_id}"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "route53:RRType"
      values   = ["NS"]
    }
    
    # Optional: Restrict to specific subdomain patterns
    dynamic "condition" {
      for_each = length(var.allowed_subdomain_patterns) > 0 ? [1] : []
      content {
        test     = "StringLike"
        variable = "route53:RRName"
        values   = var.allowed_subdomain_patterns
      }
    }
  }
  
  # Optional: Allow health check management
  dynamic "statement" {
    for_each = var.allow_health_check_management ? [1] : []
    content {
      sid    = "AllowHealthCheckManagement"
      effect = "Allow"
      
      actions = [
        "route53:CreateHealthCheck",
        "route53:DeleteHealthCheck",
        "route53:GetHealthCheck",
        "route53:ListHealthChecks",
        "route53:UpdateHealthCheck"
      ]
      
      resources = ["*"]
    }
  }
  
  # Optional: Allow CloudWatch integration for health checks
  dynamic "statement" {
    for_each = var.allow_cloudwatch_integration ? [1] : []
    content {
      sid    = "AllowCloudWatchForHealthChecks"
      effect = "Allow"
      
      actions = [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms"
      ]
      
      resources = [
        "arn:aws:cloudwatch:*:${data.aws_caller_identity.current.account_id}:alarm:*route53*",
        "arn:aws:cloudwatch:*:${data.aws_caller_identity.current.account_id}:alarm:*health-check*"
      ]
    }
  }
}

# Create the cross-account IAM role
resource "aws_iam_role" "cross_account_route53_role" {
  name                 = var.role_name
  description          = "Cross-account role for Route53 DNS management from account ${var.subdomain_account_id}"
  assume_role_policy   = data.aws_iam_policy_document.cross_account_trust_policy.json
  max_session_duration = var.role_max_session_duration

  tags = merge(var.default_tags, {
    Name           = var.role_name
    Purpose        = "CrossAccountRoute53Access"
    TrustedAccount = var.subdomain_account_id
    Domain         = var.domain_name
  })
}

# Create the IAM policy for Route53 access
resource "aws_iam_policy" "route53_cross_account_policy" {
  name        = "${var.role_name}-policy"
  description = "Policy for cross-account Route53 DNS management"
  policy      = data.aws_iam_policy_document.route53_cross_account_policy.json

  tags = merge(var.default_tags, {
    Name           = "${var.role_name}-policy"
    Purpose        = "CrossAccountRoute53Policy"
    Domain         = var.domain_name
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cross_account_policy_attachment" {
  role       = aws_iam_role.cross_account_route53_role.name
  policy_arn = aws_iam_policy.route53_cross_account_policy.arn
}

# Optional: Create a policy for the subdomain account to assume the role
resource "aws_iam_policy" "assume_role_policy" {
  count       = var.create_assume_role_policy ? 1 : 0
  name        = "${var.role_name}-assume-policy"
  description = "Policy to allow assuming the cross-account Route53 role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.cross_account_route53_role.arn
        Condition = var.external_id != null ? {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        } : {}
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name           = "${var.role_name}-assume-policy"
    Purpose        = "AssumeRoute53CrossAccountRole"
    TargetAccount  = var.subdomain_account_id
  })
}

# CloudTrail for auditing (optional)
resource "aws_cloudtrail" "route53_audit_trail" {
  count                         = var.enable_audit_logging ? 1 : 0
  name                          = "${var.role_name}-audit-trail"
  s3_bucket_name               = aws_s3_bucket.audit_logs[0].bucket
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::Route53::HostedZone"
      values = ["arn:aws:route53:::hostedzone/*"]
    }
  }

  tags = merge(var.default_tags, {
    Name    = "${var.role_name}-audit-trail"
    Purpose = "Route53CrossAccountAudit"
  })

  depends_on = [aws_s3_bucket_policy.audit_logs_policy]
}

# S3 bucket for CloudTrail logs (if audit logging is enabled)
resource "aws_s3_bucket" "audit_logs" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = "${var.role_name}-audit-logs-${random_string.bucket_suffix[0].result}"

  tags = merge(var.default_tags, {
    Name    = "${var.role_name}-audit-logs"
    Purpose = "Route53AuditLogs"
  })
}

resource "random_string" "bucket_suffix" {
  count   = var.enable_audit_logging ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "audit_logs_versioning" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = aws_s3_bucket.audit_logs[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs_encryption" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = aws_s3_bucket.audit_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "audit_logs_pab" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = aws_s3_bucket.audit_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "audit_logs_policy" {
  count  = var.enable_audit_logging ? 1 : 0
  bucket = aws_s3_bucket.audit_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.audit_logs[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.audit_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}