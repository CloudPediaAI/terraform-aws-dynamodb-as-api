# OPTIONS Method
resource "aws_api_gateway_method" "root_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = local.http_methods.OPTIONS
  authorization = "NONE"
}

# OPTIONS Method Response
resource "aws_api_gateway_method_response" "root_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  status_code = local.http_status.SUCCESS_200

  response_parameters = local.res_params_common

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [aws_api_gateway_method.root_options]
}

# OPTIONS Integration (Mock)
resource "aws_api_gateway_integration" "root_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [aws_api_gateway_method.root_options]
}

# OPTIONS Integration Response
resource "aws_api_gateway_integration_response" "root_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_options.http_method
  status_code = aws_api_gateway_method_response.root_options_200.status_code

  response_parameters = local.res_param_responses_get

  depends_on = [
    aws_api_gateway_method.root_options,
    aws_api_gateway_integration.root_options
  ]
}
