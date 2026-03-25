resource "aws_acm_certificate" "ssl_regional" {
  count = (local.create_custom_domain && local.is_ssl_regional) ? 1 : 0

  domain_name       = local.api_domain_name
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Encode then Decode Validation options to avoid conditional for_each
  domain_validations_str_regional = jsonencode((local.create_custom_domain && local.is_ssl_regional) ? aws_acm_certificate.ssl_regional[0].domain_validation_options : [
    {
      domain_name           = "dummy"
      resource_record_name  = "dummy"
      resource_record_type  = "CNAME"
      resource_record_value = "dummy"
    },
  ])
  domain_validations_regional = jsondecode(local.domain_validations_str_regional)
  # use first item for validations
  domain_validation_regional  = local.domain_validations_regional[0]
}

resource "aws_route53_record" "dvos_regional" {
  depends_on = [ aws_acm_certificate.ssl_regional ]

  count = (local.create_custom_domain && local.is_ssl_regional) ? 1 : 0

  zone_id         = local.hosted_zone
  ttl             = 60
  allow_overwrite = true
  name            = local.domain_validation_regional.resource_record_name
  records         = [local.domain_validation_regional.resource_record_value]
  type            = local.domain_validation_regional.resource_record_type
}

resource "aws_acm_certificate_validation" "ssl_regional" {
  depends_on = [aws_route53_record.dvos_regional]

  count = (local.create_custom_domain && local.is_ssl_regional) ? 1 : 0

  certificate_arn         = aws_acm_certificate.ssl_regional[0].arn
  validation_record_fqdns = [for record in aws_route53_record.dvos_regional : record.fqdn]
}
