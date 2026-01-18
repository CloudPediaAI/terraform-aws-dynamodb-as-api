resource "aws_api_gateway_method" "table_post" {
  for_each = local.tables_need_post

  authorization = local.auth_type
  authorizer_id = (local.auth_type == local.auth_types.COGNITO) ? aws_api_gateway_authorizer.cognito[0].id : null

  http_method   = local.http_methods.POST
  resource_id = aws_api_gateway_resource.table[each.key].id
  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
}

#Add a response code with the method
resource "aws_api_gateway_method_response" "table_post_method_response_200" {
  for_each = aws_api_gateway_method.table_post

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.SUCCESS_200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Method Response for POST - Input/Client Error 400
resource "aws_api_gateway_method_response" "table_post_method_response_400" {
  for_each = aws_api_gateway_method.table_post

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.CLIENT_ERR_400
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Method Response for POST - Server Error 500
resource "aws_api_gateway_method_response" "table_post_method_response_500" {
  for_each = aws_api_gateway_method.table_post

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.SERVER_ERR_500
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# resource "aws_api_gateway_integration" "table_post_int" {
#   for_each = aws_api_gateway_method.table_post

#   http_method = each.value.http_method
#   resource_id = each.value.resource_id
#   rest_api_id = each.value.rest_api_id

#   integration_http_method = "POST"
#   type                    = local.integration_types.AWS
#   uri                     = aws_lambda_function.lambda_for_post[0].invoke_arn
# }
# Integration Response for POST
resource "aws_api_gateway_integration" "table_post_int" {
  for_each = aws_api_gateway_method.table_post

  http_method = each.value.http_method
  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id

  integration_http_method = "POST"
  type                    = local.integration_types.AWS
  uri                     = aws_lambda_function.lambda_for_post[0].invoke_arn

  request_templates = {
    "application/json" = <<EOF
#set( $pKeyInput = $input.params('${lower(local.tables_need_post[each.key].partition_key.name)}') )
#set( $sKeyInput = $input.params('${lower(local.tables_need_post[each.key].sort_key.name)}') )
{
    "action_name": "ADD_ITEM",
    "entity_name": "${each.key}",
    "table_name": "${local.tables_need_get[each.key].table_name}",
    "partition_key": "${lower(local.tables_need_get[each.key].partition_key.name)}",
    "sort_key": "${lower(local.tables_need_get[each.key].sort_key.name)}",
    "body": $input.body
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "table_post_int_response_200" {
  for_each = aws_api_gateway_integration.table_post_int

  depends_on = [aws_api_gateway_integration.table_post_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = aws_api_gateway_method_response.table_post_method_response_200[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.body
    EOF
  }
}