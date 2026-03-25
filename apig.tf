resource "aws_api_gateway_rest_api" "main" {
  name = var.api_name
  
  endpoint_configuration {
    types = [ var.api_endpoint_type ]
    vpc_endpoint_ids = (var.api_endpoint_type == "PRIVATE") ? var.vpc_endpoint_ids : null
  }
  
  tags = var.tags
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod_${var.api_version}"
}

resource "aws_api_gateway_base_path_mapping" "prod" {
  count = (local.create_custom_domain) ? 1 : 0

  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  domain_name = aws_api_gateway_domain_name.api[0].domain_name
  base_path   = var.api_version
}
