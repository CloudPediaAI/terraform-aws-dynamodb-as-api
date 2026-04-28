locals {
  create_iam_role_singleton = (local.create_iam_role) ? { default = true } : {}

  dynamodb_access_policy_targets = {
    for entity_name, table_info in var.dynamodb_tables : entity_name => table_info
    if table_info != null && trimspace(try(table_info.allowed_operations, "")) != ""
  }
}

resource "aws_iam_role" "dynamodb_access_role" {
  for_each = local.create_iam_role_singleton

  name = "${var.api_name}-dynamodb-role"
  tags = var.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": ["apigateway.amazonaws.com", "lambda.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

locals {
  policy_actions_for_get = [
    "dynamodb:GetItem",
    "dynamodb:BatchGetItem",
    "dynamodb:Scan",
    "dynamodb:Query",
    "dynamodb:ConditionCheckItem"
  ]
  policy_actions_for_post   = ["dynamodb:PutItem"]
  policy_actions_for_put    = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
  policy_actions_for_delete = ["dynamodb:DeleteItem"]
}

data "aws_iam_policy_document" "dynamodb_access_policy" {
  for_each = local.dynamodb_access_policy_targets # ← stable keys from var input

  statement {
    sid = "Stm${replace(replace(each.key, "-", ""), "_", "")}"
    actions = concat(
      strcontains(upper(try(each.value.allowed_operations, "")), "R") ? local.policy_actions_for_get : [],
      (strcontains(upper(try(each.value.allowed_operations, "")), "C") && each.value.index_name == null) ? local.policy_actions_for_post : [],
      (strcontains(upper(try(each.value.allowed_operations, "")), "U") && each.value.index_name == null) ? local.policy_actions_for_put : [],
      (strcontains(upper(try(each.value.allowed_operations, "")), "D") && each.value.index_name == null) ? local.policy_actions_for_delete : []
    )
    resources = compact([
      (trimspace(coalesce(try(each.value.index_name, ""), "#")) != "#")
      ? "arn:aws:dynamodb:${data.aws_region.default.region}:${data.aws_caller_identity.current.account_id}:table/${each.value.table_name}/index/${each.value.index_name}"
      : "arn:aws:dynamodb:${data.aws_region.default.region}:${data.aws_caller_identity.current.account_id}:table/${each.value.table_name}"
    ])
  }
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  for_each = (local.create_iam_role) ? data.aws_iam_policy_document.dynamodb_access_policy : {}

  name        = "${var.api_name}-${replace(each.key, "[^A-Za-z0-9+=,.@_-]", "-")}-policy"
  description = "Policy to allow API ${var.api_name} to access DynamoDB entity ${each.key}"
  policy      = each.value.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_attach" {
  for_each = (local.create_iam_role) ? aws_iam_policy.dynamodb_access_policy : {}

  role       = aws_iam_role.dynamodb_access_role["default"].name
  policy_arn = each.value.arn
}

locals {
  role_to_access_tables = (local.create_iam_role) ? aws_iam_role.dynamodb_access_role["default"].arn : var.iam_role_arn
}
