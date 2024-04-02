resource "aws_api_gateway_resource" "skey" {
  for_each = aws_api_gateway_resource.pkey

  parent_id   = each.value.id
  path_part   = "{${(data.aws_dynamodb_table.all_tables[each.key].range_key!=null)? lower(data.aws_dynamodb_table.all_tables[each.key].range_key) : "dummy_key"}}"
  rest_api_id = each.value.rest_api_id
}

resource "aws_api_gateway_method" "skey_get" {
  for_each = aws_api_gateway_resource.skey

  authorization = "NONE"
  http_method   = "GET"
  resource_id   = each.value.id
  rest_api_id   = each.value.rest_api_id
}


#Add a response code with the method
resource "aws_api_gateway_method_response" "skey_get_method_response" {
  for_each =  aws_api_gateway_method.skey_get

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method

  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration" "skey_get_int" {
  for_each =  aws_api_gateway_method.skey_get

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
#set( $sKeyInput = $input.params('${(data.aws_dynamodb_table.all_tables[each.key].range_key!=null)? lower(data.aws_dynamodb_table.all_tables[each.key].range_key) : "dummy_value"}') )
{ 
    "TableName": "${each.key}",
    "KeyConditionExpression": "#partKey = :pKeyValue AND #sortKey = :sKeyValue",
    "ExpressionAttributeNames": { 
      "#partKey": "${data.aws_dynamodb_table.all_tables[each.key].hash_key}",
      "#sortKey": "${(data.aws_dynamodb_table.all_tables[each.key].range_key!=null)? data.aws_dynamodb_table.all_tables[each.key].range_key : "dummy_key"}" 
    },
    "ExpressionAttributeValues": { 
        ":pKeyValue":  {"S" : "$pKeyInput"},
        ":sKeyValue":  {"S" : "$sKeyInput"}
    } 
}
EOF
  }

}

# Create a response template for dynamo db structure
resource "aws_api_gateway_integration_response" "skey_get_int_response" {
  for_each = aws_api_gateway_integration.skey_get_int

  # depends_on  = [aws_api_gateway_integration.table_get_int]

  resource_id = each.value.resource_id
  rest_api_id = each.value.rest_api_id
  http_method = each.value.http_method
  
  status_code = aws_api_gateway_method_response.skey_get_method_response[each.key].status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
[
#foreach($elem in $inputRoot.Items) {
    #foreach($key in $elem.keySet())
    #set($valTypes = $elem.get($key).keySet() )
    #if( $valTypes=="[M]" )
        #set( $nestElem = $elem.get($key).M )
        ##"$key": "$nestElem",
        "$key": {
        #foreach($nKey in $nestElem.keySet())
        #set( $nValTypes = $nestElem.get($nKey).keySet() )
        #if($nValTypes=="[N]")"$nKey": $nestElem.get($nKey).N
        #elseif($nValTypes=="[BOOL]")"$nKey": $nestElem.get($nKey).BOOL
        #else
        "$nKey": "$nestElem.get($nKey).S"
        #end
        #if($foreach.hasNext),#{else}}#end
        #end
    #elseif( $valTypes=="[N]" )
    "$key": $elem.get($key).N#if($foreach.hasNext),#end
    #elseif( $valTypes=="[BOOL]" )
    "$key": $elem.get($key).BOOL#if($foreach.hasNext),#end
    #else
    "$key": "$elem.get($key).S"#if($foreach.hasNext),#end
    #end
    #end
}#if($foreach.hasNext),#end
#end
]
    EOF
  }
}