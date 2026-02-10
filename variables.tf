variable "dynamodb_tables" {
  type = map(object({
    table_name         = string
    index_name         = string
    allowed_operations = string
  }))
  description = "List of DynamoDB Tables and Index (Table details as as Map(Object('Entity Name'={table_name='Table Name', allowed_operations='CRUD'}))"
}


variable "api_name" {
  type        = string
  default     = "DynamoDB-as-API"
  description = "Name for your API. Default is DynamoDB-as-API"
  validation {
    condition = (can(regex("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\\.)*([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])$", var.api_name))
      && !strcontains(var.api_name, "..")
      && !startswith(var.api_name, "xn--")
      && !startswith(var.api_name, "sthree-")
      && !endswith(var.api_name, "-s3alias")
    && !endswith(var.api_name, "--ol-s3"))
    error_message = "Provide API name only contain alphanumeric characters, hyphens, and underscores."
  }
}

variable "api_version" {
  type        = string
  default     = "v1"
  description = "Give a version number prefixed with v. This will be used as part of base-path for API URL. Default is v1"
}

variable "iam_role_arn" {
  type        = string
  default     = null
  description = "IAM Role to access all DynamoDB tables"
}

variable "domain_name" {
  type        = string
  default     = "null"
  description = "Domain for the REST API.  This is not required if hosted_zone_id provided. API name will be used as prefix if either domain_name or hosted_zone_id is provided."
  validation {
    condition = (can(regex("^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\\.)*([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])$", var.domain_name))
      && !strcontains(var.domain_name, "..")
      && !startswith(var.domain_name, "xn--")
      && !startswith(var.domain_name, "sthree-")
      && !endswith(var.domain_name, "-s3alias")
    && !endswith(var.domain_name, "--ol-s3"))
    error_message = "Provide a valid domain name."
  }
}

variable "api_subdomain_name" {
  type        = string
  default     = ""
  description = "Subdomain Name to be part of your API URL. If not provided, api_name will be used as subdomain."
  validation {
    condition = (var.api_subdomain_name == "" || (
      can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$", var.api_subdomain_name))
      && !strcontains(var.api_subdomain_name, "--")
      && length(var.api_subdomain_name) <= 63
    ))
    error_message = "Subdomain name must contain only alphanumeric characters and hyphens, cannot start or end with a hyphen, cannot contain consecutive hyphens, and must be 63 characters or less."
  }
}

variable "hosted_zone_id" {
  type        = string
  default     = null
  description = "Id of the Hosted Zone in Route 53.  This is not required if domain_name provided"
}

variable "authorizer_type" {
  type        = string
  default     = "NONE"
  description = "Type of the authorizer. Allowed values are TOKEN for a Lambda function using a single authorization token submitted in a custom header, REQUEST for a Lambda function using incoming request parameters, or COGNITO for using an Amazon Cognito user pool. Defaults to NONE"
  validation {
    condition     = contains(["TOKEN", "REQUEST", "COGNITO", "NONE"], var.authorizer_type)
    error_message = "authorizer_type must be one of 'TOKEN', 'REQUEST', 'COGNITO', or 'NONE'"
  }
}

variable "cognito_user_pool_arns" {
  type        = set(string)
  default     = []
  description = "List of the Amazon Cognito user pool ARNs to authenticate API endpoints. This is required if authorizer_type is set to COGNITO"
}

variable "lambda_authorizer_arn" {
  type        = string
  default     = null
  description = "ARN of Lambda Authorizer. This is required if authorizer_type is set to TOKEN or REQUEST."
}

variable "lambda_authorizer_uri" {
  type        = string
  default     = null
  description = "Uniform Resource Identifier (URI) of Lambda Authorizer. This is required if authorizer_type is set to TOKEN or REQUEST. This must be a well-formed Lambda function URI in the form of arn:aws:apigateway:{region}:lambda:path/{service_api}"
}

variable "tags" {
  type        = map(any)
  description = "Key/Value pairs for the tags"
  default = {
    created_by = "Terraform Module CloudPediaAI/DynamoDB-as-API/aws"
  }
}

variable "auto_unique_id_for_missing_keys" {
  type        = bool
  default     = false
  description = "Automatically generate a Unique ID if Partition Key or Sort Key is missing while doing Adding New Items (Timestamp-based numeric IDs Number type and UUID for String type)"
}

variable "auto_audit_fields_update" {
  type        = bool
  default     = false
  description = "Automatically add or update audit fields (created_at, created_by, updated_at, updated_by) when items are added or modified in the DynamoDB tables"
}

variable "audit_field_for_created_at" {
  type        = string
  default     = "created_at"
  description = "Field name for Created At audit field (if auto_audit_fields_update is enabled)"
}

variable "audit_field_for_updated_at" {
  type        = string
  default     = "updated_at"
  description = "Field name for Updated At audit field (if auto_audit_fields_update is enabled)"
}

variable "audit_field_timestamp_format" {
  type        = string
  default     = "ISO-8601"
  description = "Format for timestamp in audit fields (if auto_audit_fields_update is enabled). Options are 'ISO-8601' or 'UNIX-EPOCH'"
  validation {
    condition     = contains(["ISO-8601", "UNIX-EPOCH"], var.audit_field_timestamp_format)
    error_message = "audit_field_timestamp_format must be either 'ISO-8601' or 'UNIX-EPOCH'"
  }
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins for the API Gateway"
  type        = string
  default     = "'*'"
}
