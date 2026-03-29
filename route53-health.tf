locals {
  route53_health_check_name = "${lower(var.api_name)}-${lower(var.api_version)}-health-check"
  # aws_api_gateway_stage.prod.invoke_url is a full URL (e.g. https://{id}.execute-api.{region}.amazonaws.com/{stage})
  # Route53 health checks need only the hostname for fqdn.
  apig_invoke_url_domain = try(
    regexall("^https?://([^/]+)", aws_api_gateway_stage.prod.invoke_url)[0][0],
    aws_api_gateway_stage.prod.invoke_url
  )
}

# Create a Health Check in Route 53 for the API Gateway endpoint
resource "aws_route53_health_check" "api_root" {
  count = (var.create_health_check) ? 1 : 0

  # fqdn              = (local.create_custom_domain)? ((local.is_ssl_regional) ? aws_api_gateway_domain_name.api_regional[0].regional_domain_name : local.api_domain_name): local.apig_invoke_url_domain
  fqdn              = local.apig_invoke_url_domain
  port              = 443
  type              = "HTTPS"
  # resource_path     = (local.create_custom_domain) ? "/${var.api_version}" : "/${aws_api_gateway_stage.prod.stage_name}"
  resource_path     = "/${aws_api_gateway_stage.prod.stage_name}"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name = local.route53_health_check_name
  })
}
