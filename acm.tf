resource "aws_acm_certificate" "ssl" {
  count   = (local.create_custom_domain) ? 1 : 0

  provider          = aws.us-east-1
  domain_name       = local.api_domain_name
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "dvos" {
  for_each = (local.create_custom_domain)? {
    for dvo in aws_acm_certificate.ssl[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }: {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = local.hosted_zone
}

resource "aws_acm_certificate_validation" "ssl" {
  count   = (local.create_custom_domain) ? 1 : 0

  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.ssl[0].arn
  validation_record_fqdns = [for record in aws_route53_record.dvos : record.fqdn]
}
