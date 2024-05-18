output "api_arn" {
  value       = aws_api_gateway_rest_api.main.arn
  description = "ARN of API created by this module"
}

output "iam_role_arn" {
  value       = local.role_to_access_tables
  description = "ARN of IAM role used to access DynamoDB tables"
}

output "api_endpoints" {
  value       = local.api_endpoints
  description = "List of API endpoints created to access/manage data in your DynamoDB tables"
}

