resource "aws_acm_certificate" "ssl" {
  count = (local.create_custom_domain) ? 1 : 0

  provider          = aws.us-east-1
  domain_name       = local.api_domain_name
  validation_method = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Encode then Decode Validation options to avoid conditional for_each
  domain_validations_str = jsonencode((local.create_custom_domain) ? aws_acm_certificate.ssl[0].domain_validation_options : [
    {
      domain_name           = "dummy"
      resource_record_name  = "dummy"
      resource_record_type  = "CNAME"
      resource_record_value = "dummy"
    },
  ])
  domain_validations = jsondecode(local.domain_validations_str)
  # use first item for validations
  domain_validation  = local.domain_validations[0]
}

# invalid for_each argument, The "for_each" map includes keys derived from resource attributes that cannot be determined until apply
# resource "aws_route53_record" "dvos" {
#   for_each = (local.create_custom_domain) ? {
#     for dvo in local.domain_validations : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }: {}

#   zone_id         = local.hosted_zone
#   ttl             = 60
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   type            = each.value.type
# }

resource "aws_route53_record" "dvos" {
  depends_on = [ aws_acm_certificate.ssl ]

  count = (local.create_custom_domain) ? 1 : 0

  zone_id         = local.hosted_zone
  ttl             = 60
  allow_overwrite = true
  name            = local.domain_validation.resource_record_name
  records         = [local.domain_validation.resource_record_value]
  type            = local.domain_validation.resource_record_type
}

resource "aws_acm_certificate_validation" "ssl" {
  depends_on = [aws_route53_record.dvos]

  count = (local.create_custom_domain) ? 1 : 0

  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.ssl[0].arn
  validation_record_fqdns = [for record in aws_route53_record.dvos : record.fqdn]
}
