resource "aws_iam_role" "dynamodb_access_role" {
  count = (local.create_iam_role) ? 1 : 0

  name = "${var.api_name}-dynamodb-role"

  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "",
			"Effect": "Allow",
			"Principal": {
				"Service": "apigateway.amazonaws.com"
			},
			"Action": "sts:AssumeRole"
		}
	]
}
EOF
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  count = (local.create_iam_role) ? 1 : 0

  name        = "${var.api_name}-dynamodb-policy"
  description = "Policy to allow API ${var.api_name} to access DynamoDB tables"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "APIPolicyToAccessDynamoDBTables",
            "Effect": "Allow",
            "Action": [
                "dynamodb:GetItem",
                "dynamodb:BatchGetItem",
                "dynamodb:Scan",
                "dynamodb:Query",
                "dynamodb:ConditionCheckItem"
            ],
            "Resource": ${local.table_arns}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_attach" {
  count = (local.create_iam_role) ? 1 : 0

  role       = aws_iam_role.dynamodb_access_role[0].name
  policy_arn = aws_iam_policy.dynamodb_access_policy[0].arn
}

locals {
  role_to_access_tables = (local.create_iam_role) ? aws_iam_role.dynamodb_access_role[0].arn : var.iam_role_arn
}


