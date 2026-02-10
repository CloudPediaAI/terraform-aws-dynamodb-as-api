resource "aws_api_gateway_method" "pkey_delete" {
  for_each = local.tables_need_pkey_delete

  authorization = local.method_auth_type
  authorizer_id = local.authorizer_id

  http_method = local.http_methods.DELETE
  resource_id = aws_api_gateway_resource.pkey[each.key].id
  rest_api_id = aws_api_gateway_resource.pkey[each.key].rest_api_id
}

# Method Response for DELETE - Success 200
resource "aws_api_gateway_method_response" "pkey_delete_method_response_200" {
  for_each = aws_api_gateway_method.pkey_delete

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.SUCCESS_200
  response_parameters = local.res_params_common
}

# Method Response for DELETE - Input/Client Error 400
resource "aws_api_gateway_method_response" "pkey_delete_method_response_400" {
  for_each = aws_api_gateway_method.pkey_delete

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.CLIENT_ERR_400
  response_parameters = local.res_params_common
}

# Method Response for DELETE - Input/Client Error 404
resource "aws_api_gateway_method_response" "pkey_delete_method_response_404" {
  for_each = aws_api_gateway_method.pkey_delete

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.NOT_FOUND_404
  response_parameters = local.res_params_common
}

# Method Response for DELETE - Server Error 500
resource "aws_api_gateway_method_response" "pkey_delete_method_response_500" {
  for_each = aws_api_gateway_method.pkey_delete

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.SERVER_ERR_500
  response_parameters = local.res_params_common
}

resource "aws_api_gateway_integration" "pkey_delete_int" {
  for_each = aws_api_gateway_method.pkey_delete

  http_method = each.value.http_method
  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id

  integration_http_method = "POST"
  type                    = local.integration_types.AWS
  uri                     = aws_lambda_function.lambda_for_delete[0].invoke_arn

  request_templates = {
    "application/json" = <<EOF
#set( $pKeyInput = $input.params('${lower(local.tables_need_delete[each.key].partition_key.name)}') )
{
    "action_name": "DELETE_ITEM",
    "entity_name": "${each.key}",
    "table_name": "${local.tables_need_delete[each.key].table_name}",
    "partition_key": "${lower(local.tables_need_delete[each.key].partition_key.name)}",
    "partition_key_value": "$pKeyInput"
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "pkey_delete_int_response_200" {
  for_each = aws_api_gateway_integration.pkey_delete_int

  depends_on = [aws_api_gateway_integration.pkey_delete_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = aws_api_gateway_method_response.pkey_delete_method_response_200[each.key].status_code
  response_parameters = local.res_param_responses_get_delete
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.body
    EOF
  }
}

resource "aws_api_gateway_integration_response" "pkey_delete_int_response_400" {
  for_each = aws_api_gateway_integration.pkey_delete_int

  depends_on = [aws_api_gateway_integration.pkey_delete_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.pkey_delete_method_response_400[each.key].status_code
  selection_pattern = ".*ERROR_400.*"

  response_parameters = local.res_param_responses_get_delete

  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage
    EOF
  }
}

resource "aws_api_gateway_integration_response" "pkey_delete_int_response_404" {
  for_each = aws_api_gateway_integration.pkey_delete_int

  depends_on = [aws_api_gateway_integration.pkey_delete_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.pkey_delete_method_response_404[each.key].status_code
  selection_pattern = ".*ERROR_404.*"

  response_parameters = local.res_param_responses_get_delete

  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage
    EOF
  }
}

resource "aws_api_gateway_integration_response" "pkey_delete_int_response_500" {
  for_each = aws_api_gateway_integration.pkey_delete_int

  depends_on = [aws_api_gateway_integration.pkey_delete_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.pkey_delete_method_response_500[each.key].status_code
  selection_pattern = ".*ERROR_500.*"

  response_parameters = local.res_param_responses_get_delete
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage
    EOF
  }
}
