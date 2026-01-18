resource "aws_api_gateway_method" "table_post" {
  for_each = local.tables_need_post

  authorization = local.auth_type
  authorizer_id = (local.auth_type == local.auth_types.COGNITO) ? aws_api_gateway_authorizer.cognito[0].id : null

  http_method   = local.http_methods.POST
  resource_id = aws_api_gateway_resource.table[each.key].id
  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
}

#Add a response code with the method
resource "aws_api_gateway_method_response" "table_post_method_response" {
  for_each = aws_api_gateway_method.table_post

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "table_post_int" {
  for_each = aws_api_gateway_method.table_post

  http_method = each.value.http_method
  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id

  integration_http_method = "POST"
  type                    = local.integration_types.AWS
  uri                     = aws_lambda_function.lambda_for_post[0].invoke_arn
}


# Create a response template for dynamo db structure
resource "aws_api_gateway_integration_response" "table_post_int_response" {
  for_each = aws_api_gateway_integration.table_post_int

  depends_on = [aws_api_gateway_integration.table_post_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = aws_api_gateway_method_response.table_post_method_response[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
    "status" : "success",
    "body" : $inputRoot.body,
}
    EOF
  }
}
