output "api_arn" {
  value = aws_api_gateway_rest_api.main.arn
  description = "ARN of API got created"
}

output "table_info" {
  value = data.aws_dynamodb_table.all_tables
}

# output "pedia_api" {
#   value = data.aws_api_gateway_resource.my_resource
# }
