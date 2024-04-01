# data "aws_api_gateway_rest_api" "pedia_test" {
#   name = "pedia-test"
# }

# data "aws_api_gateway_resource" "pedia_resource" {
#   rest_api_id = data.aws_api_gateway_rest_api.pedia_test.id
#   path        = "/"
# }

locals {
  table_names = toset(var.dynamodb_tables)
}

data "aws_dynamodb_table" "all_tables" {
  for_each = local.table_names
  name     = each.key
}

resource "aws_api_gateway_rest_api" "main" {
  name = var.api_name
}

resource "aws_api_gateway_resource" "root" {
  # for_each =  local.table_names

  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "orbitsolve-terraform-lock"
  rest_api_id = aws_api_gateway_rest_api.main.id
}

resource "aws_api_gateway_method" "root_get" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.root.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
}

resource "aws_api_gateway_integration" "root_get_int" {
  # for_each =  local.table_names

  resource_id = aws_api_gateway_resource.root.id
  rest_api_id = aws_api_gateway_rest_api.main.id
  http_method = aws_api_gateway_method.root_get.http_method

  type                    = "AWS"
  integration_http_method = "POST"
  uri         = "arn:aws:apigateway:us-west-2:dynamodb:action/Query"
  credentials = var.iam_role_arn

  request_templates = {
    "application/json" = <<EOF
{ 
    "TableName": "orbitsolve-terraform-lock",
    "KeyConditionExpression": "#partKey = :collId",
    "ExpressionAttributeNames": { "#partKey": "LockID" },
    "ExpressionAttributeValues": { 
        ":collId":  {
                "S" : "cloud-pedia-terraform-state/web-public/terraform.tfstate-md5"
            }
    } 
}
EOF
  }

}

#Add a response code with the method
resource "aws_api_gateway_method_response" "root_get_method_response" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Create a response template for dynamo db structure
resource "aws_api_gateway_integration_response" "root_get_int_response" {
  depends_on  = [aws_api_gateway_integration.root_get_int]
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.root_get.http_method
  status_code = aws_api_gateway_method_response.root_get_method_response.status_code
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

resource "aws_api_gateway_deployment" "main_deploy" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.root.id,
      aws_api_gateway_method.root_get.id,
      aws_api_gateway_integration.root_get_int.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main_dev" {
  deployment_id = aws_api_gateway_deployment.main_deploy.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "dev"
}
