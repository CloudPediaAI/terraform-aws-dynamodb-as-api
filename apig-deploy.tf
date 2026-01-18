# Prepare IDs for detecting changes which required Re-Deployment of API Gateway
# Table, PKey, SKey Resources
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
}

# GET method and integration Resources
locals {
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

# POST method and integration Resources
locals {
  table_post_method_ids = flatten([
    for method_key, method_info in aws_api_gateway_method.table_post : [
      {
        id = aws_api_gateway_method.table_post[method_key].id
      }
    ]
  ])

  table_post_int_ids = flatten([
    for int_key, int_info in aws_api_gateway_integration.table_post_int : [
      {
        id = aws_api_gateway_integration.table_post_int[int_key].id
      }
    ]
  ])
}

# PUT method and integration Resources
locals {
  table_put_method_ids = flatten([
    for method_key, method_info in aws_api_gateway_method.table_put : [
      {
        id = aws_api_gateway_method.table_put[method_key].id
      }
    ]
  ])

  table_put_int_ids = flatten([
    for int_key, int_info in aws_api_gateway_integration.table_put_int : [
      {
        id = aws_api_gateway_integration.table_put_int[int_key].id
      }
    ]
  ])
}

# DELETE method and integration Resources
locals {
  # table_delete_method_ids = flatten([
  #   for method_key, method_info in aws_api_gateway_method.table_delete : [
  #     {
  #       id = aws_api_gateway_method.table_delete[method_key].id
  #     }
  #   ]
  # ])

  pkey_delete_method_ids = flatten([
    for method_key, method_info in aws_api_gateway_method.pkey_delete : [
      {
        id = aws_api_gateway_method.pkey_delete[method_key].id
      }
    ]
  ])

  skey_delete_method_ids = flatten([
    for method_key, method_info in aws_api_gateway_method.skey_delete : [
      {
        id = aws_api_gateway_method.skey_delete[method_key].id
      }
    ]
  ])

  # table_delete_int_ids = flatten([
  #   for int_key, int_info in aws_api_gateway_integration.table_delete_int : [
  #     {
  #       id = aws_api_gateway_integration.table_delete_int[int_key].id
  #     }
  #   ]
  # ])

  pkey_delete_int_ids = flatten([
    for int_key, int_info in aws_api_gateway_integration.pkey_delete_int : [
      {
        id = aws_api_gateway_integration.pkey_delete_int[int_key].id
      }
    ]
  ])

  skey_delete_int_ids = flatten([
    for int_key, int_info in aws_api_gateway_integration.skey_delete_int : [
      {
        id = aws_api_gateway_integration.skey_delete_int[int_key].id
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
      local.table_get_int_ids, local.pkey_get_int_ids, local.skey_get_int_ids,
      local.table_post_method_ids, local.table_post_int_ids,
      local.table_put_method_ids, local.table_put_int_ids,
      local.pkey_delete_method_ids, local.skey_delete_method_ids,
      local.pkey_delete_int_ids, local.skey_delete_int_ids,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
