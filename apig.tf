resource "aws_api_gateway_rest_api" "main" {
  name = var.api_name
  tags = var.tags
}

locals {
  table_ids = flatten([
    for key, value in aws_api_gateway_resource.table : [
      {
        id = aws_api_gateway_resource.table[key].id
      }
    ]
  ])

  pkey_ids = flatten([
    for key, value in aws_api_gateway_resource.pkey : [
      {
        id = aws_api_gateway_resource.pkey[key].id
      }
    ]
  ])

  skey_ids = flatten([
    for key, value in aws_api_gateway_resource.skey : [
      {
        id = aws_api_gateway_resource.skey[key].id
      }
    ]
  ])

  table_get_method_ids = flatten([
    for method_key, method_info in aws_api_gateway_method.table_get : [
      {
        id = aws_api_gateway_method.table_get[method_key].id
      }
    ]
  ])

  pkey_get_method_ids = flatten([
    for method_key, method_info in aws_api_gateway_method.pkey_get : [
      {
        id = aws_api_gateway_method.pkey_get[method_key].id
      }
    ]
  ])

  skey_get_method_ids = flatten([
    for method_key, method_info in aws_api_gateway_method.skey_get : [
      {
        id = aws_api_gateway_method.skey_get[method_key].id
      }
    ]
  ])

  table_get_int_ids = flatten([
    for int_key, int_info in aws_api_gateway_integration.table_get_int : [
      {
        id = aws_api_gateway_integration.table_get_int[int_key].id
      }
    ]
  ])

  pkey_get_int_ids = flatten([
    for int_key, int_info in aws_api_gateway_integration.pkey_get_int : [
      {
        id = aws_api_gateway_integration.pkey_get_int[int_key].id
      }
    ]
  ])

  skey_get_int_ids = flatten([
    for int_key, int_info in aws_api_gateway_integration.skey_get_int : [
      {
        id = aws_api_gateway_integration.skey_get_int[int_key].id
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
    redeployment = sha1(jsonencode([
      local.table_ids, local.pkey_ids, local.skey_ids,
      local.table_get_method_ids, local.pkey_get_method_ids, local.skey_get_method_ids,
      local.table_get_int_ids, local.pkey_get_int_ids, local.skey_get_int_ids
    ]))
  }
  # aws_api_gateway_resource.table.id,
  # aws_api_gateway_method.table_get.id,
  # aws_api_gateway_integration.table_get_int.id,


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod_${var.api_version}"
}

resource "aws_api_gateway_base_path_mapping" "prod" {
  count   = (local.create_custom_domain) ? 1 : 0

  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  domain_name = aws_api_gateway_domain_name.api[0].domain_name
  base_path   = var.api_version
}
