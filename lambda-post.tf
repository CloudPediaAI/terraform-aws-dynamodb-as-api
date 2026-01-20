data "archive_file" "lambda_for_post" {
  count = (length(local.tables_need_post) > 0) ? 1 : 0

  type        = "zip"
  source_file = "${path.module}/lambda-post.mjs"
  output_path = "lambda-post.zip"
}

resource "aws_lambda_function" "lambda_for_post" {
  count = (length(local.tables_need_post) > 0) ? 1 : 0

  filename         = "lambda-post.zip"
  function_name    = "${var.api_name}-function-post"
  role             = aws_iam_role.dynamodb_access_role[0].arn
  handler          = "lambda-post.handler"
  runtime          = "nodejs24.x"
  source_code_hash = data.archive_file.lambda_for_post[0].output_base64sha256

  environment {
    variables = {
      AUTO_GEN_UNIQ_ID_FOR_MISSING_KEYS = var.auto_unique_id_for_missing_keys
    }
  }
}

resource "aws_lambda_permission" "lambda_for_post" {
  count      = (length(local.tables_need_post) > 0) ? 1 : 0
  depends_on = [aws_lambda_function.lambda_for_post]

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_for_post[0].function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource within the API Gateway "REST API".
  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  # source_arn = "arn:aws:execute-api:${data.aws_region.default.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.main.id}/*/${aws_api_gateway_method.method.http_method}${aws_api_gateway_resource.resource.path}"
  source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*"
}
