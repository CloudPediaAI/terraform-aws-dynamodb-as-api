resource "aws_api_gateway_authorizer" "cognito" {
  count = (local.auth_type == local.auth_types.COGNITO) ? 1 : 0

  name          = "CognitoUserPoolAuthorizer"
  type          = local.auth_type
  rest_api_id   = aws_api_gateway_rest_api.main.id
  provider_arns = var.cognito_user_pool_arns
}
