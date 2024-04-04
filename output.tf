output "api_arn" {
  value       = aws_api_gateway_rest_api.main.arn
  description = "ARN of API got created"
}

# output "iam_role_arn" {
#   value = local.role_to_access_tables
#   description = "ARN of IAM role used to access DynamoDB tables"
# }

output "table_info" {
  value = data.aws_dynamodb_table.all_tables
}

output "tables_need_endpoint" {
  value = local.tables_need_endpoint
}

output "tables_need_skey_get" {
  value = local.tables_need_skey_get
}

output "domain_info" {
  value=data.aws_route53_zone.by_id
}

# output "table_arns" {
#   value = local.table_arns
# }


# output "table_resources" {
#   value = aws_api_gateway_resource.table
# }

# output "pkey_methods" {
#   value = aws_api_gateway_method.pkey_get
# }
