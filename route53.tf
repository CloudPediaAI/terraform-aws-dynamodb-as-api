# retrive Hosted Zone using ID
data "aws_route53_zone" "by_id" {
  count   = (local.create_custom_domain && local.hosted_zone_provided) ? 1 : 0
  zone_id = var.hosted_zone_id
}

# retrieve Hosted Zone using Domain Name
data "aws_route53_zone" "by_name" {
  count = (local.create_custom_domain && !local.hosted_zone_provided) ? 1 : 0
  name  = local.domain_name
}

# extract Hosted Zone Id 
locals {
  hosted_zone        = (local.create_custom_domain) ? ((local.hosted_zone_provided) ? data.aws_route53_zone.by_id[0].zone_id : data.aws_route53_zone.by_name[0].zone_id) : "null"
  has_routing_policy = var.routing_policy != "NONE"
  need_health_check  = var.create_health_check && local.has_routing_policy
}

resource "aws_api_gateway_domain_name" "api" {
  count = (local.create_custom_domain && !local.is_ssl_regional) ? 1 : 0

  domain_name = local.api_domain_name

  # EDGE uses a CloudFront distribution and requires an ACM cert in us-east-1.
  certificate_arn = aws_acm_certificate_validation.ssl[0].certificate_arn

  endpoint_configuration {
    types = [var.api_endpoint_type]
  }
}

resource "aws_api_gateway_domain_name" "api_regional" {
  count = (local.create_custom_domain && local.is_ssl_regional) ? 1 : 0

  domain_name = local.api_domain_name

  # REGIONAL uses a regional endpoint and requires a cert in the API region.
  regional_certificate_arn = aws_acm_certificate_validation.ssl_regional[0].certificate_arn

  endpoint_configuration {
    types = [var.api_endpoint_type]
  }
}

# creating A records in Route 53 to route traffic to the API
resource "aws_route53_record" "a_record_root" {
  count = (local.create_custom_domain && !local.is_ssl_regional) ? 1 : 0

  zone_id = local.hosted_zone
  name    = local.api_domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api[0].cloudfront_domain_name
    zone_id                = aws_api_gateway_domain_name.api[0].cloudfront_zone_id
    evaluate_target_health = local.need_health_check
  }

  health_check_id = local.need_health_check ? aws_route53_health_check.api_root[0].id : null

  dynamic "latency_routing_policy" {
    for_each = local.latency_routing_policies
    content {
      region = data.aws_region.default.region
    }
  }

  # Unique identifier required when using routing policies
  set_identifier = local.has_routing_policy ? "${data.aws_region.default.region}-api" : null
}

resource "aws_route53_record" "a_record_root_regional" {
  count = (local.create_custom_domain && local.is_ssl_regional) ? 1 : 0

  zone_id = local.hosted_zone
  name    = local.api_domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.api_regional[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api_regional[0].regional_zone_id
    evaluate_target_health = local.need_health_check
  }

  health_check_id = local.need_health_check ? aws_route53_health_check.api_root[0].id : null

  dynamic "latency_routing_policy" {
    for_each = local.latency_routing_policies
    content {
      region = data.aws_region.default.region
    }
  }

  # Unique identifier required when using routing policies
  set_identifier = local.has_routing_policy ? "${data.aws_region.default.region}-api" : null
}
