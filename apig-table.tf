resource "aws_api_gateway_rest_api" "main" {
  name = var.api_name
}

resource "aws_api_gateway_resource" "table" {
  for_each = local.table_names

  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = each.key
  rest_api_id = aws_api_gateway_rest_api.main.id
}

resource "aws_api_gateway_method" "table_get" {
  for_each = aws_api_gateway_resource.table

  authorization = "NONE"
  http_method   = "GET"
  resource_id   = each.value.id
  rest_api_id   = each.value.rest_api_id
}

resource "aws_api_gateway_integration" "table_get_int" {
  for_each = aws_api_gateway_method.table_get

  http_method = each.value.http_method
  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  type        = "MOCK"
}

locals {
  table_ids = flatten([
    for key, value in aws_api_gateway_resource.table : [
      {
        id = aws_api_gateway_resource.table[key].id
      }
    ]
  ])

  method_ids = flatten([
    for method_key, method_info in aws_api_gateway_method.table_get : [
      {
        id = aws_api_gateway_method.table_get[method_key].id
      }
    ]
  ])

  integration_ids = flatten([
    for int_key, int_info in aws_api_gateway_integration.table_get_int : [
      {
        id = aws_api_gateway_integration.table_get_int[int_key].id
      }
    ]
  ])
}

resource "aws_api_gateway_deployment" "main_deploy" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([local.table_ids, local.method_ids, local.integration_ids]))
  }
  # aws_api_gateway_resource.table.id,
  # aws_api_gateway_method.table_get.id,
  # aws_api_gateway_integration.table_get_int.id,


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main_dev" {
  deployment_id = aws_api_gateway_deployment.main_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "dev"
}
