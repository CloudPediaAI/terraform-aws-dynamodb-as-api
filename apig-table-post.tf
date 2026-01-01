resource "aws_api_gateway_method" "table_post" {
  for_each = local.tables_need_post

  authorization = local.auth_type
  authorizer_id = (local.auth_type == local.auth_types.COGNITO) ? aws_api_gateway_authorizer.cognito[0].id : null

  http_method   = local.http_methods.POST
  resource_id = aws_api_gateway_resource.table[each.key].id
  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
}

resource "aws_api_gateway_integration" "table_post_int" {
  for_each = aws_api_gateway_method.table_post

  http_method = each.value.http_method
  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
#   type        = local.integration_types.MOCK

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_for_post.invoke_arn
}

