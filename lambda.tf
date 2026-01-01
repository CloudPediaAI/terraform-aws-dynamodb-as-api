locals {
  lambda_for_post = "code"
}

data "archive_file" "lambda_for_post" {
  type        = "zip"
  source_file = "lambda-post.js"
  output_path = "lambda_post.zip"
}

resource "aws_lambda_function" "lambda_for_post" {
  for_each = local.tables_need_post

  filename         = "lambda.zip"
  function_name    = "${each.key}_post_function"
  role             = aws_iam_role.post_invoke_lambda.arn
  handler          = "lambda.lambda_handler"
  runtime          = "nodejs20.x"
  source_code_hash = data.archive_file.lambda_for_post.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = "table"
      INDEX_NAME = "index"
    }
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_for_post.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource within the API Gateway "REST API".
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.default.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
}
