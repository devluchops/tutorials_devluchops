output "subdomain_hosted_zone_id" {
  description = "The hosted zone ID of the subdomain"
  value       = aws_route53_zone.subdomain.zone_id
}

output "subdomain_hosted_zone_arn" {
  description = "The ARN of the subdomain hosted zone"
  value       = aws_route53_zone.subdomain.arn
}

output "subdomain_name_servers" {
  description = "List of name servers for the subdomain hosted zone"
  value       = aws_route53_zone.subdomain.name_servers
}

output "subdomain_name" {
  description = "The subdomain name"
  value       = var.subdomain_name
}

output "parent_domain" {
  description = "The parent domain name"
  value       = var.parent_domain
}

output "parent_hosted_zone_id" {
  description = "The hosted zone ID of the parent domain"
  value       = data.aws_route53_zone.parent_domain.zone_id
}

output "ns_record_in_parent" {
  description = "NS record created in the parent domain"
  value = {
    name    = aws_route53_record.subdomain_ns_in_parent.name
    type    = aws_route53_record.subdomain_ns_in_parent.type
    ttl     = aws_route53_record.subdomain_ns_in_parent.ttl
    records = aws_route53_record.subdomain_ns_in_parent.records
  }
}

output "subdomain_account_id" {
  description = "AWS Account ID where subdomain resources are created"
  value       = data.aws_caller_identity.subdomain.account_id
}

output "central_account_id" {
  description = "AWS Account ID of the central account"
  value       = data.aws_caller_identity.central.account_id
}

output "cross_account_role_arn" {
  description = "ARN of the cross-account role used"
  value       = var.cross_account_role_arn
}

output "health_check_id" {
  description = "ID of the Route53 health check (if created)"
  value       = var.create_health_check && var.subdomain_ip != "" ? aws_route53_health_check.subdomain_health[0].id : null
}

output "health_check_alarm_name" {
  description = "Name of the CloudWatch alarm for health check (if created)"
  value       = var.create_health_check && var.subdomain_ip != "" ? aws_cloudwatch_metric_alarm.health_check_alarm[0].alarm_name : null
}

output "dns_log_group_name" {
  description = "Name of the CloudWatch log group for DNS queries (if enabled)"
  value       = var.enable_dns_logging ? aws_cloudwatch_log_group.dns_query_logs[0].name : null
}

output "dns_log_group_arn" {
  description = "ARN of the CloudWatch log group for DNS queries (if enabled)"
  value       = var.enable_dns_logging ? aws_cloudwatch_log_group.dns_query_logs[0].arn : null
}

output "aws_region" {
  description = "AWS region where the resources are created"
  value       = var.aws_region
}

# Output records created (for verification)
output "created_records" {
  description = "Summary of DNS records created in the subdomain"
  value = {
    subdomain_a_record = var.create_subdomain_a_record && var.subdomain_ip != "" ? "${var.subdomain_name} A ${var.subdomain_ip}" : "Not created"
    cname_records      = length(var.cname_records) > 0 ? [for name, target in var.cname_records : "${name} CNAME ${target}"] : []
    txt_records        = length(var.txt_records) > 0 ? [for name, value in var.txt_records : "${name} TXT ${value}"] : []
    a_records          = length(var.a_records) > 0 ? [for name, ip in var.a_records : "${name} A ${ip}"] : []
    aaaa_records       = length(var.aaaa_records) > 0 ? [for name, ip in var.aaaa_records : "${name} AAAA ${ip}"] : []
    mx_records         = length(var.mx_records) > 0 ? "${var.subdomain_name} MX ${join(", ", var.mx_records)}" : "Not created"
  }
}

# DNS delegation validation information
output "delegation_info" {
  description = "Information about DNS delegation setup"
  value = {
    subdomain                = var.subdomain_name
    parent_domain           = var.parent_domain
    subdomain_name_servers  = aws_route53_zone.subdomain.name_servers
    ns_record_created       = "NS record created in ${var.parent_domain} pointing to ${var.subdomain_name}"
    delegation_status       = "Active"
    validation_command      = "dig NS ${var.subdomain_name}"
  }
}

# Cross-account setup summary
output "cross_account_summary" {
  description = "Summary of cross-account setup"
  value = {
    central_account        = data.aws_caller_identity.central.account_id
    subdomain_account      = data.aws_caller_identity.subdomain.account_id
    cross_account_role     = var.cross_account_role_arn
    parent_hosted_zone     = data.aws_route53_zone.parent_domain.zone_id
    subdomain_hosted_zone  = aws_route53_zone.subdomain.zone_id
    delegation_established = true
  }
}

# Useful DNS testing commands
output "dns_testing_commands" {
  description = "Commands to test DNS setup"
  value = {
    test_ns_delegation     = "dig NS ${var.subdomain_name}"
    test_subdomain_resolution = "nslookup ${var.subdomain_name}"
    test_parent_domain     = "dig NS ${var.parent_domain}"
    check_propagation      = "dig +trace ${var.subdomain_name}"
    test_specific_ns       = "dig @${aws_route53_zone.subdomain.name_servers[0]} ${var.subdomain_name}"
  }
}