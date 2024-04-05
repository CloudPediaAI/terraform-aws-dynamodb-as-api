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
  tables_has_ops = {
    for key, table_info in var.dynamodb_tables : key => table_info if(table_info != null && table_info.allowed_operations != null)
  }
}

data "aws_dynamodb_table" "all_tables" {
  for_each = local.tables_has_ops
  name     = each.value.table_name
}

# prepare list of tables based on allowed_operations and the presence of sort_key.name 
locals {
  tables_need_endpoint_array = flatten([
    for key, value in data.aws_dynamodb_table.all_tables : [
      (strcontains(upper(local.tables_has_ops[key].allowed_operations), "C")
        || strcontains(upper(local.tables_has_ops[key].allowed_operations), "R")
        || strcontains(upper(local.tables_has_ops[key].allowed_operations), "U")
      || strcontains(upper(local.tables_has_ops[key].allowed_operations), "D")) ?
      {
        entity_name = key
        table_name  = value.name
        table_arn   = value.arn

        partition_key = tolist(value.attribute)[index(value.attribute.*.name, value.hash_key)]
        has_sort_key  = (value.range_key != null)
        sort_key      = (value.range_key != null) ? tolist(value.attribute)[index(value.attribute.*.name, value.range_key)] : null

        need_post   = strcontains(upper(local.tables_has_ops[key].allowed_operations), "C")
        need_get    = strcontains(upper(local.tables_has_ops[key].allowed_operations), "R")
        need_put    = strcontains(upper(local.tables_has_ops[key].allowed_operations), "U")
        need_delete = strcontains(upper(local.tables_has_ops[key].allowed_operations), "D")
      } : null
    ]
  ])

  # removing empty object and converting to map 
  tables_need_endpoint = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if table_info != null
  }

  # if allowed_operations contains R (Read)
  tables_need_get = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if(table_info != null && table_info.need_get)
  }
  # if allowed_operations contains C (Create)
  tables_need_post = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if(table_info != null && table_info.need_post)
  }
  # if allowed_operations contains U (Update)
  tables_need_put = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if(table_info != null && table_info.need_put)
  }
  # if allowed_operations contains D (Delete)
  tables_need_delete = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if(table_info != null && table_info.need_delete)
  }
  # if allowed_operations contains R (Read) or D (Delete)
  tables_need_get_delete = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if(table_info != null && (table_info.need_get || table_info.need_delete))
  }

  # Since all tables will have a partition-key
  tables_need_pkey_get        = local.tables_need_get
  tables_need_pkey_delete     = local.tables_need_delete
  tables_need_pkey_get_delete = local.tables_need_get_delete

  # if table has a SORT-KEY and allowed_operations contains R (Read)
  tables_need_skey_get = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if(table_info != null && table_info.has_sort_key && table_info.need_get)
  }
  # if table has a SORT-KEY and allowed_operations contains D (Delete)
  tables_need_skey_delete = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if(table_info != null && table_info.has_sort_key && table_info.need_delete)
  }
  # if table has a SORT-KEY and allowed_operations contains R (Read) or D (Delete)
  tables_need_skey_get_delete = {
    for table_info in local.tables_need_endpoint_array : "${table_info.entity_name}" => table_info if(table_info != null && table_info.has_sort_key && (table_info.need_get || table_info.need_delete))
  }

  get_integration_uri = "arn:aws:apigateway:${data.aws_region.default.name}:dynamodb:action/Query"

  create_iam_role = (var.iam_role_arn == null)

  hosted_zone_provided = (var.hosted_zone_id != null)
  domain_provided      = (var.domain_name != "null")
  create_custom_domain = (local.hosted_zone_provided || local.domain_provided)

  domain_name     = (local.create_custom_domain) ? ((local.domain_provided) ? lower(var.domain_name) : data.aws_route53_zone.by_id[0].name) : null
  api_domain_name = (local.create_custom_domain) ? "${var.api_name}.${local.domain_name}" : null
  custom_api_url  = (local.create_custom_domain) ? "https://${var.api_name}.${local.domain_name}/${var.api_version}" : null
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

  # api_endpoints_array = concat(local.api_endpoints_pkey, local.api_endpoints_skey)
  # api_endpoints = flatten([
  #   for entity_name, table_info in local.tables_need_endpoint : {
  #     for key, ep in local.api_endpoints_array : "${entity_name}" => ep if key == entity_name
  #   }
  # ])

}
