resource "aws_api_gateway_method" "table_post" {
  for_each = local.tables_need_post

  authorization = local.auth_type
  authorizer_id = (local.auth_type == local.auth_types.COGNITO) ? aws_api_gateway_authorizer.cognito[0].id : null

  http_method = local.http_methods.POST
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
  response_parameters = local.res_params_common
}

# Method Response for POST - Input/Client Error 400
resource "aws_api_gateway_method_response" "table_post_method_response_400" {
  for_each = aws_api_gateway_method.table_post

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.CLIENT_ERR_400
  response_models = {
    "application/json" = "Error"
  }
  response_parameters = local.res_params_common
}

# Method Response for POST - Not Found Error 404
resource "aws_api_gateway_method_response" "table_post_method_response_404" {
  for_each = aws_api_gateway_method.table_post

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.NOT_FOUND_404
  response_models = {
    "application/json" = "Error"
  }
  response_parameters = local.res_params_common
}

# Method Response for POST - Server Error 500
resource "aws_api_gateway_method_response" "table_post_method_response_500" {
  for_each = aws_api_gateway_method.table_post

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = local.http_status.SERVER_ERR_500
  response_parameters = local.res_params_common
}

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
{
    "action_name": "ADD_ITEM",
    "entity_name": "${each.key}",
    "table_name": "${local.tables_need_post[each.key].table_name}",
    "partition_key": "${lower(local.tables_need_post[each.key].partition_key.name)}",
    "partition_key_type": "${local.tables_need_post[each.key].partition_key.type}",
    "sort_key": "${lower(local.tables_need_post[each.key].sort_key.name)}",
    "sort_key_type": "${local.tables_need_post[each.key].sort_key.type}",
    "body": $input.body
}
EOF
  }
}

# Integration Responses - Order matters: most specific patterns first
resource "aws_api_gateway_integration_response" "table_post_int_response_400" {
  for_each = aws_api_gateway_integration.table_post_int

  depends_on = [aws_api_gateway_integration.table_post_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.table_post_method_response_400[each.key].status_code
  selection_pattern = "\\{.*\"statusCode\":400.*\\}"

  response_parameters = local.res_param_responses_post

  # Optional: Transform the output using a mapping template
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
#if($inputRoot.body)
$inputRoot.body
#else
$input.path('$')
#end    
EOF
  }
}

resource "aws_api_gateway_integration_response" "table_post_int_response_404" {
  for_each = aws_api_gateway_integration.table_post_int

  depends_on = [aws_api_gateway_integration.table_post_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.table_post_method_response_404[each.key].status_code
  selection_pattern = "\\{.*\"statusCode\":404.*\\}"

  response_parameters = local.res_param_responses_post

  # Optional: Transform the output using a mapping template
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
#if($inputRoot.body)
$inputRoot.body
#else
$input.path('$')
#end    
EOF
  }
}

resource "aws_api_gateway_integration_response" "table_post_int_response_500" {
  for_each = aws_api_gateway_integration.table_post_int

  depends_on = [aws_api_gateway_integration.table_post_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.table_post_method_response_500[each.key].status_code
  selection_pattern = "\\{.*\"statusCode\":5[0-9][0-9].*\\}"

  response_parameters = local.res_param_responses_post

  # Optional: Transform the output using a mapping template
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
#if($inputRoot.body)
$inputRoot.body
#else
$input.path('$')
#end    
EOF
  }
}

# Default success response - must be last
resource "aws_api_gateway_integration_response" "table_post_int_response_200" {
  for_each = aws_api_gateway_integration.table_post_int

  depends_on = [aws_api_gateway_integration.table_post_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = aws_api_gateway_method_response.table_post_method_response_200[each.key].status_code
  selection_pattern = ""  # Default response - catches anything not matched by other patterns

  response_parameters = local.res_param_responses_post
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.body
    EOF
  }
}
