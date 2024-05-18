terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.36.0"
      configuration_aliases = [aws.us-east-1, aws]
    }
  }
}

data "aws_region" "default" {}

locals {
  http_methods = {
    GET    = "GET",
    POST   = "POST",
    PUT    = "PUT",
    DELETE = "DELETE"
  }

  integration_types = {
    MOCK       = "MOCK",      # not calling any real backend
    AWS        = "AWS",       # for AWS services
    HTTP       = "HTTP",      # for HTTP backends 
    AWS_PROXY  = "AWS_PROXY"  # for Lambda proxy integration
    HTTP_PROXY = "HTTP_PROXY" # for HTTP proxy integration
  }

  auth_types = {
    NONE    = "NONE",
    CUSTOM  = "CUSTOM",
    AWSIAM  = "AWS_IAM",
    COGNITO = "COGNITO_USER_POOLS"
  }

  # tables without index
  tables_has_ops = {
    for key, table_info in var.dynamodb_tables : key => table_info if(table_info != null && table_info.index_name == null && table_info.allowed_operations != null)
  }

  # tables with index
  indexes_has_ops = {
    for key, table_info in var.dynamodb_tables : key => table_info if(table_info != null && table_info.index_name != null && table_info.allowed_operations != null)
  }
}

data "aws_dynamodb_table" "all_tables" {
  for_each = local.tables_has_ops
  name     = each.value.table_name
}

data "aws_dynamodb_table" "all_indexes" {
  for_each = local.indexes_has_ops
  name     = each.value.table_name
}

locals {
  // preparing schema of all tables
  tables = flatten([
    for key, value in data.aws_dynamodb_table.all_tables : [
      {
        entity_name      = key
        table_index_name = "${key}_${value.name}"
        is_index         = false

        table_name = value.name
        index_name = null
        table_arn  = value.arn
        hash_key   = value.hash_key
        range_key  = (value.range_key != null && value.range_key != "") ? value.range_key : null
        attribute  = value.attribute

        need_post   = strcontains(upper(var.dynamodb_tables[key].allowed_operations), "C")
        need_get    = strcontains(upper(var.dynamodb_tables[key].allowed_operations), "R")
        need_put    = strcontains(upper(var.dynamodb_tables[key].allowed_operations), "U")
        need_delete = strcontains(upper(var.dynamodb_tables[key].allowed_operations), "D")
        need_method = (
          strcontains(upper(var.dynamodb_tables[key].allowed_operations), "C") ||
          strcontains(upper(var.dynamodb_tables[key].allowed_operations), "R") ||
          strcontains(upper(var.dynamodb_tables[key].allowed_operations), "U") ||
          strcontains(upper(var.dynamodb_tables[key].allowed_operations), "D")
        )
      }
    ]
  ])

  // preparing schema of all Local Secondary Indexes
  local_indexes = flatten([
    for key, value in data.aws_dynamodb_table.all_indexes : [
      for index_info in value.local_secondary_index : {
        entity_name      = key
        table_index_name = "${key}_${value.name}_${index_info.name}"
        is_index         = true

        table_name = value.name
        index_name = index_info.name
        // preparing ARN for index by suffixing index-name
        table_arn = "${value.arn}/index/${index_info.name}"
        // local indexes inherit hash_key from its table, so taking hash_key from the table
        hash_key  = value.hash_key
        range_key = (index_info.range_key != null && index_info.range_key != "") ? index_info.range_key : null
        attribute = value.attribute

        need_post   = false
        need_get    = strcontains(upper(var.dynamodb_tables[key].allowed_operations), "R")
        need_put    = false
        need_delete = false
        need_method = strcontains(upper(var.dynamodb_tables[key].allowed_operations), "R")
      }
    ]
  ])

  // preparing schema of all Global Secondary Indexes
  global_indexes = flatten([
    for key, value in data.aws_dynamodb_table.all_indexes : [
      for index_info in value.global_secondary_index : {
        entity_name      = key
        table_index_name = "${key}_${value.name}_${index_info.name}"
        is_index         = true

        table_name = value.name
        index_name = index_info.name
        // preparing ARN for index by suffixing index-name
        table_arn = "${value.arn}/index/${index_info.name}"
        hash_key  = index_info.hash_key
        range_key = (index_info.range_key != null && index_info.range_key != "") ? index_info.range_key : null
        attribute = value.attribute

        need_post   = false
        need_get    = strcontains(upper(var.dynamodb_tables[key].allowed_operations), "R")
        need_put    = false
        need_delete = false
        need_method = strcontains(upper(var.dynamodb_tables[key].allowed_operations), "R")
      }
    ]
  ])

  tables_and_indexes = distinct(concat(local.tables, local.local_indexes, local.global_indexes))

  tables_and_indexes_info = {
    for tiinfo in local.tables_and_indexes : tiinfo.table_index_name => tiinfo
  }

}

locals {
  # prepare list of tables/indexes based on allowed_operations and the presence of sort_key.name 
  tables_need_endpoint_array = flatten([
    for key, value in local.tables_and_indexes_info : [
      ((var.dynamodb_tables[value.entity_name].table_name == value.table_name && var.dynamodb_tables[value.entity_name].index_name == value.index_name) &&
        (value.need_method)
      ) ?
      {
        entity_name      = value.entity_name
        table_name       = value.table_name
        is_index         = value.is_index
        index_name       = value.index_name
        table_index_name = value.table_index_name
        table_arn        = value.table_arn

        partition_key = tolist(value.attribute)[index(value.attribute.*.name, value.hash_key)]
        has_sort_key  = (value.range_key != null)
        sort_key      = (value.range_key != null) ? tolist(value.attribute)[index(value.attribute.*.name, value.range_key)] : null

        need_post   = value.need_post
        need_get    = value.need_get
        need_put    = value.need_put
        need_delete = value.need_delete
        need_method = value.need_method
      } : null
    ]
  ])

  # removing empty object and converting to map 
  tables_need_endpoint = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if table_info != null
  }

  # if allowed_operations contains R (Read)
  tables_need_get = {
    for key, table_info in local.tables_need_endpoint : key => table_info if(table_info != null && table_info.need_get)
  }

  # if allowed_operations contains C (Create)
  tables_need_post = {
    for key, table_info in local.tables_need_endpoint : key => table_info if(table_info != null && table_info.need_post)
  }

  # if allowed_operations contains U (Update)
  tables_need_put = {
    for key, table_info in local.tables_need_endpoint : key => table_info if(table_info != null && table_info.need_put)
  }

  # if allowed_operations contains D (Delete)
  tables_need_delete = {
    for key, table_info in local.tables_need_endpoint : key => table_info if(table_info != null && table_info.need_delete)
  }

  # if allowed_operations contains R (Read) or D (Delete)
  tables_need_get_delete = {
    for key, table_info in local.tables_need_endpoint : key => table_info if(table_info != null && (table_info.need_get || table_info.need_delete))
  }

  # Since all tables/indexes will have a partition-key
  tables_need_pkey_get        = local.tables_need_get
  tables_need_pkey_delete     = local.tables_need_delete
  tables_need_pkey_get_delete = local.tables_need_get_delete

  # if table has a SORT-KEY and allowed_operations contains R (Read)
  tables_need_skey_get = {
    for key, table_info in local.tables_need_endpoint : key => table_info if(table_info != null && table_info.has_sort_key && table_info.need_get)
  }

  # if table has a SORT-KEY and allowed_operations contains D (Delete)
  tables_need_skey_delete = {
    for key, table_info in local.tables_need_endpoint : key => table_info if(table_info != null && table_info.has_sort_key && table_info.need_delete)
  }

  # if table has a SORT-KEY and allowed_operations contains R (Read) or D (Delete)
  tables_need_skey_get_delete = {
    for key, table_info in local.tables_need_endpoint : key => table_info if(table_info != null && table_info.has_sort_key && (table_info.need_get || table_info.need_delete))
  }

  get_integration_uri = "arn:aws:apigateway:${data.aws_region.default.name}:dynamodb:action/Query"

  create_iam_role = (var.iam_role_arn == null)
  auth_type       = (var.cognito_user_pool_arns != null && length(var.cognito_user_pool_arns) > 0) ? local.auth_types.COGNITO : local.auth_types.NONE

  hosted_zone_provided = (var.hosted_zone_id != null)
  domain_provided      = (var.domain_name != "null")
  create_custom_domain = (local.hosted_zone_provided || local.domain_provided)

  domain_name     = (local.create_custom_domain) ? ((local.domain_provided) ? lower(var.domain_name) : data.aws_route53_zone.by_id[0].name) : null
  api_domain_name = (local.create_custom_domain) ? "${lower(var.api_name)}.${local.domain_name}" : null
  custom_api_url  = (local.create_custom_domain) ? "https://${lower(var.api_name)}.${local.domain_name}/${var.api_version}" : null
  api_base_url    = (local.create_custom_domain) ? local.custom_api_url : aws_api_gateway_stage.prod.invoke_url

  api_endpoints_pkey = flatten([
    for key, value in local.tables_need_pkey_get : {
      "${key}" = {
        "get-${key}-by-${value.partition_key.name}" : "${local.api_base_url}${aws_api_gateway_resource.pkey[key].path}"
      }
    }
    ]
  )

  api_endpoints_skey = flatten([
    for key, value in local.tables_need_skey_get : {
      "${key}" = {
        "get-${key}-by-${value.partition_key.name}-and-${value.sort_key.name}" : "${local.api_base_url}${aws_api_gateway_resource.skey[key].path}"
      }
    }
  ])

  api_endpoints = concat(local.api_endpoints_pkey, local.api_endpoints_skey)
}
