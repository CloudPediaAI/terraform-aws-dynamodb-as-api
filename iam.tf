resource "aws_iam_role" "dynamodb_access_role" {
  count = (local.create_iam_role) ? 1 : 0

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
  for_each = local.tables_need_endpoint

  statement {
    sid = "Stm${each.key}"
    actions   = concat(
      ((each.value.need_get)?local.policy_actions_for_get:[]),
      ((each.value.need_post)?local.policy_actions_for_post:[]),
      ((each.value.need_put)?local.policy_actions_for_put:[]),
      ((each.value.need_delete)?local.policy_actions_for_delete:[]),
      )
    resources = [each.value.table_arn]
  }
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  for_each = (local.create_iam_role) ? data.aws_iam_policy_document.dynamodb_access_policy : {}

  name        = "${var.api_name}-${local.tables_need_endpoint[each.key].table_index_name}-policy"
  description = "Policy to allow API ${var.api_name} to access DynamoDB table-index ${local.tables_need_endpoint[each.key].table_index_name}"
  policy = each.value.json
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_attach" {
  for_each = (local.create_iam_role) ? aws_iam_policy.dynamodb_access_policy : {}

  role       = aws_iam_role.dynamodb_access_role[0].name
  policy_arn = each.value.arn
}

locals {
  role_to_access_tables = (local.create_iam_role) ? aws_iam_role.dynamodb_access_role[0].arn : var.iam_role_arn
}
