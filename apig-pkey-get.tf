resource "aws_api_gateway_resource" "pkey" {
  for_each = aws_api_gateway_resource.table

  parent_id   = each.value.id
  path_part   = "{${lower(data.aws_dynamodb_table.all_tables[each.key].hash_key)}}"
  rest_api_id = each.value.rest_api_id
}

resource "aws_api_gateway_method" "pkey_get" {
  for_each = aws_api_gateway_resource.pkey

  authorization = "NONE"
  http_method   = "GET"
  resource_id   = each.value.id
  rest_api_id   = each.value.rest_api_id
}


#Add a response code with the method
resource "aws_api_gateway_method_response" "pkey_get_method_response" {
  for_each =  aws_api_gateway_method.pkey_get

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "pkey_get_int" {
  for_each =  aws_api_gateway_method.pkey_get

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  type                    = "AWS"
  integration_http_method = "POST"
  uri         = "arn:aws:apigateway:us-west-2:dynamodb:action/Query"
  credentials = var.iam_role_arn

  request_templates = {
    "application/json" = <<EOF
#set( $pKeyInput = $input.params('${lower(data.aws_dynamodb_table.all_tables[each.key].hash_key)}') )
{ 
    "TableName": "${each.key}",
    "KeyConditionExpression": "#partKey = :pKeyValue",
    "ExpressionAttributeNames": { "#partKey": "${data.aws_dynamodb_table.all_tables[each.key].hash_key}" },
    "ExpressionAttributeValues": { 
        ":pKeyValue":  {
                "S" : "$pKeyInput"
            }
    } 
}
EOF
  }

}

# Create a response template for dynamo db structure
resource "aws_api_gateway_integration_response" "pkey_get_int_response" {
  for_each = aws_api_gateway_integration.pkey_get_int

  # depends_on  = [aws_api_gateway_integration.table_get_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method
  
  status_code = aws_api_gateway_method_response.pkey_get_method_response[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = local.get_response_template
  }
}