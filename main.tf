# Zip the lambda dir
data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

#
# The lambda taking care of running the tasks in scheduled fasion
#
resource "aws_lambda_function" "this" {
  count            = var.create ? 1 : 0
  function_name    = var.name
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  timeout          = 30
  filename         = "${path.module}/lambda.zip"
  source_code_hash = data.archive_file.this.output_base64sha256
  role             = element(concat(aws_iam_role.this.*.arn, [""]), 0)

  publish = true
  tags    = var.tags

  lifecycle {
    ignore_changes = [filename]
  }
}

data "aws_iam_policy_document" "trust_policy" {
  count = var.create ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}


# Policy for the Lambda Logging & ECS
data "aws_iam_policy_document" "this" {
  count = var.create ? 1 : 0

  statement {
    actions = [
      "iam:PassRole",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecs:RunTask",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:ListTaskDefinitions",
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/*"]

    effect = "Allow"
  }

  statement {
    actions = ["logs:PutLogEvents"]

    resources = ["arn:aws:logs:*:*:log-group:/aws/lambda/*"]

    effect = "Allow"
  }
}

# Role for the lambda
resource "aws_iam_role" "this" {
  count              = var.create ? 1 : 0
  name               = var.name
  assume_role_policy = element(concat(data.aws_iam_policy_document.trust_policy.*.json, [""]), 0)
}

resource "aws_iam_role_policy" "this" {
  count  = var.create ? 1 : 0
  role   = element(concat(aws_iam_role.this.*.id, [""]), 0)
  policy = data.aws_iam_policy_document.this[0].json
}

