terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.36.0"
      configuration_aliases = [aws.us-east-1, aws]
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  table_names     = toset(var.dynamodb_tables)
  domain_name     = lower(var.domain_name)
  api_domain_name = "${var.api_name}.${local.domain_name}"
}

data "aws_dynamodb_table" "all_tables" {
  for_each = local.table_names
  name     = each.key
}

locals {
  table_arns = flatten([
    for key, value in data.aws_dynamodb_table.all_tables : [
      data.aws_dynamodb_table.all_tables[key].arn
    ]
  ])
}
