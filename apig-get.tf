# Add a GET method to the API root for Health Check
resource "aws_api_gateway_method" "root_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = local.http_methods.GET
  authorization = "NONE"
}

# Configure the integration (e.g., MOCK)
resource "aws_api_gateway_integration" "root_get_int" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [aws_api_gateway_method.root_get]
}

# Add a 200 response for the GET method
resource "aws_api_gateway_method_response" "root_get_200" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = local.http_status.SUCCESS_200

  response_parameters = local.res_params_health_check
}

# Add an integration response for the 200 status code
resource "aws_api_gateway_integration_response" "root_get_200_int_resp" {   
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = aws_api_gateway_method_response.root_get_200.status_code

  response_parameters = local.res_param_responses_health_check

  # status: Required field. Common values are "pass" (healthy), "fail" (unhealthy), or "warn" (healthy but with issues).
  response_templates = {
    "application/json" = jsonencode({
      # statusCode = 200
      status     = "pass"
      message    = "API is healthy"
    })
  }

  depends_on = [
    aws_api_gateway_method.root_get,
    aws_api_gateway_integration.root_get_int,
  ]
}
