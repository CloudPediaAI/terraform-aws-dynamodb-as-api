resource "aws_api_gateway_resource" "pkey" {
  for_each = local.tables_need_pkey_get_delete

  parent_id   = aws_api_gateway_resource.table[each.key].id
  path_part   = "{${each.value.partition_key.name}}"
  rest_api_id = aws_api_gateway_resource.table[each.key].rest_api_id
}

resource "aws_api_gateway_method" "pkey_get" {
  # for_each = aws_api_gateway_resource.pkey
  for_each = local.tables_need_pkey_get

  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.pkey[each.key].id
  rest_api_id   = aws_api_gateway_resource.pkey[each.key].rest_api_id
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
  uri         = local.get_integration_uri
  credentials = local.role_to_access_tables

  request_templates = {
    "application/json" = <<EOF
#set( $pKeyInput = $input.params('${lower(local.tables_need_get[each.key].partition_key.name)}') )
{ 
    "TableName": "${local.tables_need_get[each.key].table_name}",
    "KeyConditionExpression": "#partKey = :pKeyValue",
    "ExpressionAttributeNames": { "#partKey": "${local.tables_need_get[each.key].partition_key.name}" },
    "ExpressionAttributeValues": { 
        ":pKeyValue":  {
                "${local.tables_need_get[each.key].partition_key.type}" : "$pKeyInput"
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
    "application/json" = <<EOF
#set($inputRoot = $input.path('$'))
{
    "status" : "success",
    "count": $inputRoot.Count,
    #if($inputRoot.Count==0)
    "message": "No records found",
    "data": null
    #else
    "data": { "${each.key}":  [
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
        #end#if($foreach.hasNext),#end  
    #elseif( $valTypes=="[L]" )
        #set( $nestElem = $elem.get($key).L )
        "$key": [
        #foreach($nItem in $nestElem)
        #set( $nValTypes = $nItem.keySet() )
        #if($nValTypes=="[N]")$nItem.N
        #elseif($nValTypes=="[BOOL]")$nItem.BOOL
        #else
        "$nItem.S"
        #end
        #if($foreach.hasNext),#{else}]#end
        #end#if($foreach.hasNext),#end          
    #elseif( $valTypes=="[SS]" )
        #set( $nestElem = $elem.get($key).SS )
        "$key": [
        #foreach($eachValue in $nestElem)
        "$eachValue"#if($foreach.hasNext),#end
        #end ]#if($foreach.hasNext),#end  
    #elseif( $valTypes=="[NS]" )
        #set( $nestElem = $elem.get($key).NS )
        "$key": [
        #foreach($eachValue in $nestElem)
        $eachValue#if($foreach.hasNext),#end
        #end ]#if($foreach.hasNext),#end  
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
]}
#end
}
    EOF
  }
}