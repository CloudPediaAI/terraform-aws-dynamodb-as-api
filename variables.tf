variable "api_name" {
  type        = string
  default     = "DynamoDB-as-API"
  description = "API Name"
}

variable "iam_role_arn" {
  type = string
  description = "IAM Role to access all DynamoDB tables"
}

variable "dynamodb_tables" {
  type = list(string)
  description = "List of DynamoDB Tables (Table Names as String Array)"
}


# variable "dynamodb_arn" {
#   type        = string
#   default     = null
#   description = "ARN of DynamoDB database"
# }

# variable "partition_key" {
#   type        = string
#   description = "Partition Key of DynamoDB"
# }

# variable "sort_key" {
#   type        = string
#   default     = null
#   description = "Partition Key of DynamoDB"
# }

variable "tags" {
  type        = map(any)
  description = "Key/Value pairs for the tags"
  default = {
    created_by = "Terraform Module CloudPediaAI/DynamoDB-as-API/aws"
  }
}
