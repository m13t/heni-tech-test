data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "lambda_access" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "LambdaDemo"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "lambda" {
  name   = "LambdaDemo"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_access.json
}

data "archive_file" "payload" {
  type        = "zip"
  source_file = format("%s/../lambda/lambda", path.root)
  output_path = format("%s/../payload.zip", path.root)
}

resource "aws_lambda_function" "api_handler" {
  function_name = "APIHandler"

  role = aws_iam_role.lambda.arn

  runtime = "go1.x"
  handler = "lambda"

  publish = true

  filename         = data.archive_file.payload.output_path
  source_code_hash = data.archive_file.payload.output_base64sha256
}

resource "aws_lambda_alias" "stages" {
  for_each = local.stages

  name        = each.key
  description = format("Alias for '%s' stage", each.key)

  function_name    = aws_lambda_function.api_handler.arn
  function_version = lookup(each.value, "function_version", "$LATEST")
}

resource "aws_lambda_permission" "api" {
  for_each = local.stages

  statement_id = format("Allow%sInvoke", title(each.key))
  action       = "lambda:InvokeFunction"
  principal    = "apigateway.amazonaws.com"

  function_name = aws_lambda_function.api_handler.function_name
  qualifier     = each.key

  source_arn = format("%s/*/*", aws_apigatewayv2_stage.stages[each.key].execution_arn)
}

output "lambda_latest" {
  value = aws_lambda_function.api_handler.version
}

output "lambda_deployments" {
  value = {
    for k, v in aws_lambda_alias.stages :
    k => v.function_version
  }
}
