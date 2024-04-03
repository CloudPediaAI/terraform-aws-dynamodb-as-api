variable "dynamodb_tables" {
  type = list(string)
  description = "List of DynamoDB Tables (Table Names as String Array)"
}

variable "api_name" {
  type        = string
  default     = "DynamoDB-as-API"
  description = "Name for your API. Default is DynamoDB-as-API"
}

variable "api_version" {
  type        = string
  default     = "v1"
  description = "Given a version number prefixed with v. This will be used as part base-path for API URL. Default is v1"
}

variable "iam_role_arn" {
  type = string
  description = "IAM Role to access all DynamoDB tables"
}

variable "domain_name" {
  type        = string
  description = "Domain for the REST API. API name will be used as prefix if domain_name or hosted_zone_id is provided."
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

variable "hosted_zone_id" {
  type        = string
  default = null
  description = "Id of the Hosted Zone in Route 53"
}

variable "tags" {
  type        = map(any)
  description = "Key/Value pairs for the tags"
  default = {
    created_by = "Terraform Module CloudPediaAI/DynamoDB-as-API/aws"
  }
}
