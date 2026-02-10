resource "aws_api_gateway_authorizer" "lambda" {
  count = local.need_lambda_authorizer ? 1 : 0

  name                   = "LambdaAuthorizer"
  type                   = local.auth_type
  rest_api_id            = aws_api_gateway_rest_api.main.id
  authorizer_uri         = var.lambda_authorizer_uri
  authorizer_credentials = aws_iam_role.lambda_auth_assume_role[0].arn
}

resource "aws_iam_role" "lambda_auth_assume_role" {
  count = local.need_lambda_authorizer ? 1 : 0

  name               = "${var.api_name}-apig-auth-invoke-role"
  path               = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_auth_invocation_role" {
  count = local.need_lambda_authorizer ? 1 : 0

  name = "${var.api_name}-apig-auth-invoke-policy"
  role = aws_iam_role.lambda_auth_assume_role[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:InvokeFunction"]
        Resource = [var.lambda_authorizer_arn]
      }
    ]
  })
}
