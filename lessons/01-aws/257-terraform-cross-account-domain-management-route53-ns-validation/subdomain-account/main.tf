terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Local provider for subdomain account
provider "aws" {
  alias  = "subdomain"
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

# Provider for central account (using assume role)
provider "aws" {
  alias  = "central"
  region = var.aws_region

  assume_role {
    role_arn     = var.cross_account_role_arn
    session_name = "terraform-subdomain-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
    external_id  = var.external_id
  }

  default_tags {
    tags = var.default_tags
  }
}

# Data source to get current AWS account ID (subdomain account)
data "aws_caller_identity" "subdomain" {
  provider = aws.subdomain
}

# Data source to get central account information
data "aws_caller_identity" "central" {
  provider = aws.central
}

# Get the parent domain hosted zone from central account
data "aws_route53_zone" "parent_domain" {
  provider     = aws.central
  name         = var.parent_domain
  private_zone = false
}

# Create the subdomain hosted zone in the subdomain account
resource "aws_route53_zone" "subdomain" {
  provider      = aws.subdomain
  name          = var.subdomain_name
  comment       = "Hosted zone for subdomain ${var.subdomain_name}"
  force_destroy = var.force_destroy_hosted_zone

  tags = merge(var.default_tags, {
    Name        = "${var.subdomain_name}-hosted-zone"
    Environment = var.environment
    Type        = "Subdomain"
    ParentDomain = var.parent_domain
  })
}

# Create NS records in the parent domain (central account) pointing to subdomain name servers
resource "aws_route53_record" "subdomain_ns_in_parent" {
  provider = aws.central
  zone_id  = data.aws_route53_zone.parent_domain.zone_id
  name     = var.subdomain_name
  type     = "NS"
  ttl      = var.ns_record_ttl
  records  = aws_route53_zone.subdomain.name_servers

  depends_on = [aws_route53_zone.subdomain]
}

# Create basic DNS records for the subdomain
resource "aws_route53_record" "subdomain_a_record" {
  count    = var.create_subdomain_a_record && var.subdomain_ip != "" ? 1 : 0
  provider = aws.subdomain
  zone_id  = aws_route53_zone.subdomain.zone_id
  name     = var.subdomain_name
  type     = "A"
  ttl      = var.record_ttl
  records  = [var.subdomain_ip]
}

# Create CNAME records for additional subdomains
resource "aws_route53_record" "cname_records" {
  for_each = var.cname_records
  provider = aws.subdomain
  zone_id  = aws_route53_zone.subdomain.zone_id
  name     = each.key
  type     = "CNAME"
  ttl      = var.record_ttl
  records  = [each.value]
}

# Create TXT records (useful for verification, SPF, etc.)
resource "aws_route53_record" "txt_records" {
  for_each = var.txt_records
  provider = aws.subdomain
  zone_id  = aws_route53_zone.subdomain.zone_id
  name     = each.key
  type     = "TXT"
  ttl      = var.record_ttl
  records  = [each.value]
}

# Create A records for additional hostnames
resource "aws_route53_record" "a_records" {
  for_each = var.a_records
  provider = aws.subdomain
  zone_id  = aws_route53_zone.subdomain.zone_id
  name     = each.key
  type     = "A"
  ttl      = var.record_ttl
  records  = [each.value]
}

# Create AAAA records for IPv6
resource "aws_route53_record" "aaaa_records" {
  for_each = var.aaaa_records
  provider = aws.subdomain
  zone_id  = aws_route53_zone.subdomain.zone_id
  name     = each.key
  type     = "AAAA"
  ttl      = var.record_ttl
  records  = [each.value]
}

# Create MX records for subdomain email
resource "aws_route53_record" "mx_records" {
  count    = length(var.mx_records) > 0 ? 1 : 0
  provider = aws.subdomain
  zone_id  = aws_route53_zone.subdomain.zone_id
  name     = var.subdomain_name
  type     = "MX"
  ttl      = var.record_ttl
  records  = var.mx_records
}

# Create CloudWatch log group for DNS query logging (optional)
resource "aws_cloudwatch_log_group" "dns_query_logs" {
  count             = var.enable_dns_logging ? 1 : 0
  provider          = aws.subdomain
  name              = "/aws/route53/${var.subdomain_name}"
  retention_in_days = var.dns_log_retention_days

  tags = merge(var.default_tags, {
    Name        = "${var.subdomain_name}-dns-logs"
    Environment = var.environment
  })
}

# Enable DNS query logging for subdomain
resource "aws_route53_query_log" "subdomain_logs" {
  count           = var.enable_dns_logging ? 1 : 0
  provider        = aws.subdomain
  depends_on      = [aws_cloudwatch_log_group.dns_query_logs]
  destination_arn = aws_cloudwatch_log_group.dns_query_logs[0].arn
  hosted_zone_id  = aws_route53_zone.subdomain.zone_id
}

# Create Route53 health check for the subdomain (optional)
resource "aws_route53_health_check" "subdomain_health" {
  count                           = var.create_health_check && var.subdomain_ip != "" ? 1 : 0
  provider                        = aws.subdomain
  fqdn                            = var.subdomain_name
  port                            = var.health_check_port
  type                            = var.health_check_type
  resource_path                   = var.health_check_path
  failure_threshold               = var.health_check_failure_threshold
  request_interval                = var.health_check_interval
  cloudwatch_alarm_region         = var.aws_region
  cloudwatch_alarm_name           = "${var.subdomain_name}-health-check-alarm"
  insufficient_data_health_status = "Failure"

  tags = merge(var.default_tags, {
    Name        = "${var.subdomain_name}-health-check"
    Environment = var.environment
  })
}

# Create CloudWatch alarm for health check (if enabled)
resource "aws_cloudwatch_metric_alarm" "health_check_alarm" {
  count               = var.create_health_check && var.subdomain_ip != "" ? 1 : 0
  provider            = aws.subdomain
  alarm_name          = "${var.subdomain_name}-health-check-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "This metric monitors health check for ${var.subdomain_name}"
  alarm_actions       = var.health_check_alarm_actions

  dimensions = {
    HealthCheckId = aws_route53_health_check.subdomain_health[0].id
  }

  tags = merge(var.default_tags, {
    Name        = "${var.subdomain_name}-health-check-alarm"
    Environment = var.environment
  })
}

# Local values for validation
locals {
  subdomain_parts = split(".", var.subdomain_name)
  parent_parts    = split(".", var.parent_domain)
  
  # Validate that subdomain is actually a subdomain of parent domain
  is_valid_subdomain = length(local.subdomain_parts) > length(local.parent_parts) && 
                      join(".", slice(local.subdomain_parts, -length(local.parent_parts), length(local.subdomain_parts))) == var.parent_domain
}

# Validation check
resource "null_resource" "validate_subdomain" {
  count = local.is_valid_subdomain ? 0 : 1
  
  provisioner "local-exec" {
    command = "echo 'ERROR: ${var.subdomain_name} is not a valid subdomain of ${var.parent_domain}' && exit 1"
  }
}