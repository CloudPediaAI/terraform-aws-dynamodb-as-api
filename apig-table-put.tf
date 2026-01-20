resource "aws_api_gateway_method" "table_put" {
  for_each = local.tables_need_put

  authorization = local.auth_type
  authorizer_id = (local.auth_type == local.auth_types.COGNITO) ? aws_api_gateway_authorizer.cognito[0].id : null

  http_method = local.http_methods.PUT
  resource_id = aws_api_gateway_resource.table[each.key].id
  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
}

# Method Response for PUT - Success 200
resource "aws_api_gateway_method_response" "table_put_method_response_200" {
  for_each = aws_api_gateway_method.table_put

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.SUCCESS_200
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Method Response for PUT - Input/Client Error 400
resource "aws_api_gateway_method_response" "table_put_method_response_400" {
  for_each = aws_api_gateway_method.table_put

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.CLIENT_ERR_400
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Method Response for PUT - Not Found Error 404
resource "aws_api_gateway_method_response" "table_put_method_response_404" {
  for_each = aws_api_gateway_method.table_put

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.NOT_FOUND_404
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Method Response for PUT - Server Error 500
resource "aws_api_gateway_method_response" "table_put_method_response_500" {
  for_each = aws_api_gateway_method.table_put

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.SERVER_ERR_500
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "table_put_int" {
  for_each = aws_api_gateway_method.table_put

  http_method = each.value.http_method
  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id

  integration_http_method = "POST"
  type                    = local.integration_types.AWS
  uri                     = aws_lambda_function.lambda_for_put[0].invoke_arn

  request_templates = {
    "application/json" = <<EOF
{
    "action_name": "UPDATE_ITEM",
    "entity_name": "${each.key}",
    "table_name": "${local.tables_need_put[each.key].table_name}",
    "partition_key": "${lower(local.tables_need_put[each.key].partition_key.name)}",
    "partition_key_type": "${local.tables_need_put[each.key].partition_key.type}",
    "sort_key": "${lower(local.tables_need_put[each.key].sort_key.name)}",
    "sort_key_type": "${local.tables_need_put[each.key].sort_key.type}",
    "body": $input.body
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "table_put_int_response_200" {
  for_each = aws_api_gateway_integration.table_put_int

  depends_on = [aws_api_gateway_integration.table_put_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = aws_api_gateway_method_response.table_put_method_response_200[each.key].status_code
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

resource "aws_api_gateway_integration_response" "table_put_int_response_400" {
  for_each = aws_api_gateway_integration.table_put_int

  depends_on = [aws_api_gateway_integration.table_put_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.table_put_method_response_400[each.key].status_code
  selection_pattern = ".*ERROR_400.*"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage
    EOF
  }
}

resource "aws_api_gateway_integration_response" "table_put_int_response_404" {
  for_each = aws_api_gateway_integration.table_put_int

  depends_on = [aws_api_gateway_integration.table_put_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.table_put_method_response_404[each.key].status_code
  selection_pattern = ".*ERROR_404.*"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage
    EOF
  }
}

resource "aws_api_gateway_integration_response" "table_put_int_response_500" {
  for_each = aws_api_gateway_integration.table_put_int

  depends_on = [aws_api_gateway_integration.table_put_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.table_put_method_response_500[each.key].status_code
  selection_pattern = ".*ERROR_500.*"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage
    EOF
  }
}
