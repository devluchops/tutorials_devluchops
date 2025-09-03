output "cross_account_role_arn" {
  description = "ARN of the cross-account IAM role"
  value       = aws_iam_role.cross_account_route53_role.arn
}

output "cross_account_role_name" {
  description = "Name of the cross-account IAM role"
  value       = aws_iam_role.cross_account_route53_role.name
}

output "cross_account_policy_arn" {
  description = "ARN of the Route53 cross-account policy"
  value       = aws_iam_policy.route53_cross_account_policy.arn
}

output "cross_account_policy_name" {
  description = "Name of the Route53 cross-account policy"
  value       = aws_iam_policy.route53_cross_account_policy.name
}

output "assume_role_policy_arn" {
  description = "ARN of the assume role policy (if created)"
  value       = var.create_assume_role_policy ? aws_iam_policy.assume_role_policy[0].arn : null
}

output "assume_role_policy_name" {
  description = "Name of the assume role policy (if created)"
  value       = var.create_assume_role_policy ? aws_iam_policy.assume_role_policy[0].name : null
}

output "central_account_id" {
  description = "AWS Account ID where the role is created"
  value       = data.aws_caller_identity.current.account_id
}

output "subdomain_account_id" {
  description = "AWS Account ID that can assume the role"
  value       = var.subdomain_account_id
}

output "domain_hosted_zone_id" {
  description = "Hosted zone ID for the main domain"
  value       = data.aws_route53_zone.main_domain.zone_id
}

output "domain_name" {
  description = "Domain name for which cross-account access is configured"
  value       = var.domain_name
}

output "external_id" {
  description = "External ID used for role assumption (if configured)"
  value       = var.external_id
  sensitive   = true
}

output "role_max_session_duration" {
  description = "Maximum session duration for the role in seconds"
  value       = aws_iam_role.cross_account_route53_role.max_session_duration
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail for audit logging (if enabled)"
  value       = var.enable_audit_logging ? aws_cloudtrail.route53_audit_trail[0].name : null
}

output "audit_logs_bucket" {
  description = "S3 bucket name for audit logs (if enabled)"
  value       = var.enable_audit_logging ? aws_s3_bucket.audit_logs[0].bucket : null
}

output "audit_logs_bucket_arn" {
  description = "S3 bucket ARN for audit logs (if enabled)"
  value       = var.enable_audit_logging ? aws_s3_bucket.audit_logs[0].arn : null
}

# Output for easy copy-paste to subdomain account configuration
output "subdomain_account_terraform_config" {
  description = "Terraform configuration values for the subdomain account"
  value = {
    central_account_id     = data.aws_caller_identity.current.account_id
    cross_account_role_arn = aws_iam_role.cross_account_route53_role.arn
    parent_domain         = var.domain_name
    external_id           = var.external_id
  }
}

# Output assume role command for testing
output "test_assume_role_command" {
  description = "AWS CLI command to test role assumption"
  value = var.external_id != null ? "aws sts assume-role --role-arn ${aws_iam_role.cross_account_route53_role.arn} --role-session-name test-session --external-id ${var.external_id}" : "aws sts assume-role --role-arn ${aws_iam_role.cross_account_route53_role.arn} --role-session-name test-session"
  sensitive = var.external_id != null
}

# Output AWS CLI profile configuration
output "aws_cli_profile_config" {
  description = "AWS CLI profile configuration for cross-account access"
  value = {
    profile_name = "central-cross-account"
    config = templatefile("${path.module}/aws-profile-template.txt", {
      role_arn    = aws_iam_role.cross_account_route53_role.arn
      external_id = var.external_id
      region      = var.aws_region
    })
  }
}

# Security and compliance information
output "security_summary" {
  description = "Security configuration summary"
  value = {
    role_arn                 = aws_iam_role.cross_account_route53_role.arn
    trusted_account          = var.subdomain_account_id
    external_id_required     = var.external_id != null
    mfa_required            = var.require_mfa
    ip_restrictions         = length(var.allowed_source_ips) > 0
    allowed_source_ips      = var.allowed_source_ips
    max_session_duration    = var.role_max_session_duration
    audit_logging_enabled   = var.enable_audit_logging
    health_checks_allowed   = var.allow_health_check_management
    cloudwatch_allowed      = var.allow_cloudwatch_integration
    subdomain_patterns      = var.allowed_subdomain_patterns
  }
}

# Verification commands
output "verification_commands" {
  description = "Commands to verify the setup"
  value = {
    check_role_exists       = "aws iam get-role --role-name ${aws_iam_role.cross_account_route53_role.name}"
    list_role_policies      = "aws iam list-attached-role-policies --role-name ${aws_iam_role.cross_account_route53_role.name}"
    test_assume_role        = var.external_id != null ? "aws sts assume-role --role-arn ${aws_iam_role.cross_account_route53_role.arn} --role-session-name test --external-id ${var.external_id}" : "aws sts assume-role --role-arn ${aws_iam_role.cross_account_route53_role.arn} --role-session-name test"
    check_hosted_zone       = "aws route53 get-hosted-zone --id ${data.aws_route53_zone.main_domain.zone_id}"
    list_cloudtrail         = var.enable_audit_logging ? "aws cloudtrail describe-trails --trail-name-list ${aws_cloudtrail.route53_audit_trail[0].name}" : "No CloudTrail configured"
  }
}