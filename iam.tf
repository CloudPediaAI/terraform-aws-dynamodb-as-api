# resource "aws_iam_role" "dynamodb_access_role" {
#   count = (var.iam_role_arn == null) ? 1 : 0

#   name = "${var.api_name}-role"

#   assume_role_policy = <<EOF
#     {
# 	"Version": "2012-10-17",
# 	"Statement": [
# 		{
# 			"Sid": "",
# 			"Effect": "Allow",
# 			"Principal": {
# 				"Service": "apigateway.amazonaws.com"
# 			},
# 			"Action": "sts:AssumeRole"
# 		}
# 	]
# }
# EOF
# }

# resource "aws_iam_policy" "policy" {
#   count = (var.iam_role_arn == null) ? 1 : 0

#   name        = "${var.api_name}-policy"
#   description = "Policy to allow API ${var.api_name} to access DynamoDB tables"

#   policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "ReadOnlyAPIActionsOnBooks",
#             "Effect": "Allow",
#             "Action": [
#                 "dynamodb:GetItem",
#                 "dynamodb:BatchGetItem",
#                 "dynamodb:Scan",
#                 "dynamodb:Query",
#                 "dynamodb:ConditionCheckItem"
#             ],
#             "Resource": "arn:aws:dynamodb:us-west-2:123456789012:table/Books"
#         }
#     ]
# }
# EOF
# }

# resource "aws_iam_role_policy_attachment" "test-attach" {
#   count = (var.iam_role_arn == null) ? 1 : 0

#   role       = "${aws_iam_role.dynamodb_access_role[0].name}"
#   policy_arn = "${aws_iam_policy.policy[0].arn}"
# }

# locals {
#   role_to_access_tables = (var.iam_role_arn != null) ? var.iam_role_arn : aws_iam_role.dynamodb_access_role.arn
# }


