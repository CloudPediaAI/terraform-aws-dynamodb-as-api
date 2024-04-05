# create endpoints for each table
resource "aws_api_gateway_resource" "table" {
  for_each = local.tables_need_endpoint

  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = each.key
  rest_api_id = aws_api_gateway_rest_api.main.id
}

resource "aws_api_gateway_method" "table_get" {
  for_each = aws_api_gateway_resource.table

  authorization = "NONE"
  http_method   = "GET"
  resource_id   = each.value.id
  rest_api_id   = each.value.rest_api_id
}

resource "aws_api_gateway_integration" "table_get_int" {
  for_each = aws_api_gateway_method.table_get

  http_method = each.value.http_method
  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  type        = "MOCK"
}
