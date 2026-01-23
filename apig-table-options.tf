# OPTIONS Method
resource "aws_api_gateway_method" "table_options" {
  for_each = aws_api_gateway_resource.table

  resource_id = each.value.id
  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
  http_method   = local.http_methods.OPTIONS
  authorization = "NONE"
}

# OPTIONS Method Response
resource "aws_api_gateway_method_response" "table_options_200" {
  for_each = aws_api_gateway_resource.table

  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
  resource_id = aws_api_gateway_resource.table[each.key].id
  http_method = aws_api_gateway_method.table_options[each.key].http_method
  status_code = "200"

  response_parameters = local.res_params_common

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [ aws_api_gateway_method.table_options ]
}

# OPTIONS Integration (Mock)
resource "aws_api_gateway_integration" "table_options" {
  for_each = aws_api_gateway_resource.table

  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
  resource_id = aws_api_gateway_resource.table[each.key].id
  http_method = aws_api_gateway_method.table_options[each.key].http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [ aws_api_gateway_method.table_options ]
}

# OPTIONS Integration Response
resource "aws_api_gateway_integration_response" "table_options_200" {
  for_each = aws_api_gateway_resource.table

  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
  resource_id = aws_api_gateway_resource.table[each.key].id
  http_method = aws_api_gateway_method.table_options[each.key].http_method
  status_code = aws_api_gateway_method_response.table_options_200[each.key].status_code

  response_parameters = local.res_params_responses_get_post_put

  depends_on = [
    aws_api_gateway_method.table_options,
    aws_api_gateway_integration.table_options
    ]
}