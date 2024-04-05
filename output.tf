output "api_arn" {
  value       = aws_api_gateway_rest_api.main.arn
  description = "ARN of API created by this module"
}

output "iam_role_arn" {
  value = local.role_to_access_tables
  description = "ARN of IAM role used to access DynamoDB tables"
}

output "api_endpoints" {
  value = local.api_endpoints
}

# output "table_info" {
#   value = data.aws_dynamodb_table.all_tables
# }

# output "tables_need_endpoint" {
#   value = local.tables_need_endpoint
# }