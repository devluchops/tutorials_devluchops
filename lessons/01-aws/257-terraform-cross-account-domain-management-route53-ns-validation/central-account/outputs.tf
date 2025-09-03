output "hosted_zone_id" {
  description = "The hosted zone ID of the main domain"
  value       = aws_route53_zone.main_domain.zone_id
}

output "hosted_zone_arn" {
  description = "The ARN of the hosted zone"
  value       = aws_route53_zone.main_domain.arn
}

output "name_servers" {
  description = "List of name servers for the hosted zone"
  value       = aws_route53_zone.main_domain.name_servers
}

output "domain_name" {
  description = "The domain name"
  value       = var.domain_name
}

output "zone_name_servers" {
  description = "Name servers for the zone (formatted for external registrar)"
  value = formatlist("%s.", aws_route53_zone.main_domain.name_servers)
}

output "verification_record" {
  description = "Domain verification TXT record value"
  value       = var.create_verification_record ? random_string.verification_token[0].result : null
  sensitive   = true
}

output "health_check_id" {
  description = "ID of the Route53 health check (if created)"
  value       = var.create_health_check && var.main_domain_ip != "" ? aws_route53_health_check.main_domain_health[0].id : null
}

output "health_check_alarm_name" {
  description = "Name of the CloudWatch alarm for health check (if created)"
  value       = var.create_health_check && var.main_domain_ip != "" ? aws_cloudwatch_metric_alarm.health_check_alarm[0].alarm_name : null
}

output "dns_log_group_name" {
  description = "Name of the CloudWatch log group for DNS queries (if enabled)"
  value       = var.enable_dns_logging ? aws_cloudwatch_log_group.dns_query_logs[0].name : null
}

output "dns_log_group_arn" {
  description = "ARN of the CloudWatch log group for DNS queries (if enabled)"
  value       = var.enable_dns_logging ? aws_cloudwatch_log_group.dns_query_logs[0].arn : null
}

output "account_id" {
  description = "AWS Account ID where the resources are created"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region where the resources are created"
  value       = var.aws_region
}

output "tags" {
  description = "Tags applied to resources"
  value       = var.default_tags
}

# Output for cross-account access information
output "cross_account_info" {
  description = "Information needed for cross-account access setup"
  value = {
    central_account_id = data.aws_caller_identity.current.account_id
    hosted_zone_id     = aws_route53_zone.main_domain.zone_id
    domain_name        = var.domain_name
    name_servers       = aws_route53_zone.main_domain.name_servers
  }
}

# Output records created (for verification)
output "created_records" {
  description = "Summary of DNS records created"
  value = {
    main_a_record    = var.create_main_a_record && var.main_domain_ip != "" ? "${var.domain_name} A ${var.main_domain_ip}" : "Not created"
    www_cname        = var.create_www_record ? "www.${var.domain_name} CNAME ${var.domain_name}" : "Not created"
    verification_txt = var.create_verification_record ? "${var.domain_name} TXT v=verification-***" : "Not created"
    mx_records       = var.create_mx_records && length(var.mx_records) > 0 ? "${var.domain_name} MX ${join(", ", var.mx_records)}" : "Not created"
    spf_record       = var.create_spf_record && var.spf_record != "" ? "${var.domain_name} TXT ${var.spf_record}" : "Not created"
  }
}