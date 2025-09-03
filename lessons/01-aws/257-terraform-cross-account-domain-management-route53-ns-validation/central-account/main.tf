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

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Create the main hosted zone for the domain
resource "aws_route53_zone" "main_domain" {
  name          = var.domain_name
  comment       = "Main hosted zone for ${var.domain_name}"
  force_destroy = var.force_destroy_hosted_zone

  tags = merge(var.default_tags, {
    Name        = "${var.domain_name}-hosted-zone"
    Environment = var.environment
    Type        = "MainDomain"
  })
}

# Create a TXT record for domain verification (optional)
resource "aws_route53_record" "domain_verification" {
  count   = var.create_verification_record ? 1 : 0
  zone_id = aws_route53_zone.main_domain.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300
  records = [
    "v=verification-${random_string.verification_token[0].result}"
  ]
}

resource "random_string" "verification_token" {
  count   = var.create_verification_record ? 1 : 0
  length  = 32
  special = false
  upper   = false
}

# Create basic DNS records for the main domain
resource "aws_route53_record" "main_a_record" {
  count   = var.create_main_a_record && var.main_domain_ip != "" ? 1 : 0
  zone_id = aws_route53_zone.main_domain.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [var.main_domain_ip]
}

# Create CNAME record for www subdomain
resource "aws_route53_record" "www_cname" {
  count   = var.create_www_record ? 1 : 0
  zone_id = aws_route53_zone.main_domain.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}

# Create MX records for email
resource "aws_route53_record" "mx_records" {
  count   = var.create_mx_records && length(var.mx_records) > 0 ? 1 : 0
  zone_id = aws_route53_zone.main_domain.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 300
  records = var.mx_records
}

# Create SPF record for email security
resource "aws_route53_record" "spf_record" {
  count   = var.create_spf_record && var.spf_record != "" ? 1 : 0
  zone_id = aws_route53_zone.main_domain.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300
  records = [var.spf_record]
}

# Output the name servers for external registrar configuration
locals {
  name_servers = aws_route53_zone.main_domain.name_servers
}

# Create CloudWatch log group for DNS query logging (optional)
resource "aws_cloudwatch_log_group" "dns_query_logs" {
  count             = var.enable_dns_logging ? 1 : 0
  name              = "/aws/route53/${var.domain_name}"
  retention_in_days = var.dns_log_retention_days

  tags = merge(var.default_tags, {
    Name        = "${var.domain_name}-dns-logs"
    Environment = var.environment
  })
}

# Enable DNS query logging
resource "aws_route53_query_log" "main_domain_logs" {
  count                    = var.enable_dns_logging ? 1 : 0
  depends_on               = [aws_cloudwatch_log_group.dns_query_logs]
  destination_arn          = aws_cloudwatch_log_group.dns_query_logs[0].arn
  hosted_zone_id           = aws_route53_zone.main_domain.zone_id
}

# Create Route53 health check for the main domain (optional)
resource "aws_route53_health_check" "main_domain_health" {
  count                            = var.create_health_check && var.main_domain_ip != "" ? 1 : 0
  fqdn                             = var.domain_name
  port                             = var.health_check_port
  type                             = var.health_check_type
  resource_path                    = var.health_check_path
  failure_threshold                = var.health_check_failure_threshold
  request_interval                 = var.health_check_interval
  cloudwatch_alarm_region          = var.aws_region
  cloudwatch_alarm_name            = "${var.domain_name}-health-check-alarm"
  insufficient_data_health_status  = "Failure"

  tags = merge(var.default_tags, {
    Name        = "${var.domain_name}-health-check"
    Environment = var.environment
  })
}

# Create CloudWatch alarm for health check (if enabled)
resource "aws_cloudwatch_metric_alarm" "health_check_alarm" {
  count               = var.create_health_check && var.main_domain_ip != "" ? 1 : 0
  alarm_name          = "${var.domain_name}-health-check-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors health check for ${var.domain_name}"
  alarm_actions       = var.health_check_alarm_actions

  dimensions = {
    HealthCheckId = aws_route53_health_check.main_domain_health[0].id
  }

  tags = merge(var.default_tags, {
    Name        = "${var.domain_name}-health-check-alarm"
    Environment = var.environment
  })
}