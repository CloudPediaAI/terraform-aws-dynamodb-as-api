resource "aws_api_gateway_method" "table_post" {
  for_each = local.tables_need_post

  authorization = local.method_auth_type
  authorizer_id = local.authorizer_id

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

  status_code         = local.http_status.SUCCESS_200
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

  status_code         = local.http_status.SERVER_ERR_500
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
%{if try(local.tables_need_post[each.key].sort_key, null) != null~}
    "sort_key": "${lower(local.tables_need_post[each.key].sort_key.name)}",
    "sort_key_type": "${local.tables_need_post[each.key].sort_key.type}",
%{endif~}
    "audit_field_ct": "${local.audit_field_for_created_at}",
    "audit_ts_format": "${local.audit_field_timestamp_format}",  
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

  response_parameters = local.res_param_responses_post
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.body
    EOF
  }
}

resource "aws_api_gateway_integration_response" "table_post_int_response_400" {
  for_each = aws_api_gateway_integration.table_post_int

  depends_on = [aws_api_gateway_integration.table_post_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code       = aws_api_gateway_method_response.table_post_method_response_400[each.key].status_code
  selection_pattern = ".*ERROR_400.*"

  response_parameters = local.res_param_responses_post

  # Optional: Transform the output using a mapping template
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage    
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
  selection_pattern = ".*ERROR_404.*"

  response_parameters = local.res_param_responses_post

  # Optional: Transform the output using a mapping template
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage    
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
  selection_pattern = ".*ERROR_500.*"

  response_parameters = local.res_param_responses_post

  # Optional: Transform the output using a mapping template
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
$inputRoot.errorMessage    
EOF
  }
}
