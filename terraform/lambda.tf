// Policy to allow our lambda role to be assumed by the Lambda service
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

// Policy to allow our lambda role to push logs to CloudWatch
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

// The role for our Lambda to use
resource "aws_iam_role" "lambda" {
  name               = "LambdaDemo"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

// Attaches the above policies to the Lambda role
resource "aws_iam_role_policy" "lambda" {
  name   = "LambdaDemo"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_access.json
}

// Creates a zip file with the lambda binary output
data "archive_file" "payload" {
  type        = "zip"
  source_file = format("%s/../lambda/lambda", path.root)
  output_path = format("%s/../payload.zip", path.root)
}

// Create our lambda function with the given payload and IAM role.
// Our lambda function is written in Golang so we set the runtime to go1.x.
// We also mark any changes to publish a new version of the function.
resource "aws_lambda_function" "api_handler" {
  function_name = "APIHandler"

  role = aws_iam_role.lambda.arn

  runtime = "go1.x"
  handler = "lambda"

  publish = true

  filename         = data.archive_file.payload.output_path
  source_code_hash = data.archive_file.payload.output_base64sha256
}

// For each of our stages that we've defined (dev, test, live), we create a
// Lambda alias for our function. We also point the alias to the version number
// from the config in our `config.tf` file, otherwise default to the built-in
// version identifier: $LATEST.
resource "aws_lambda_alias" "stages" {
  for_each = local.stages

  name        = each.key
  description = format("Alias for '%s' stage", each.key)

  function_name    = aws_lambda_function.api_handler.arn
  function_version = lookup(each.value, "function_version", "$LATEST")
}

// Similar to above, we add permissions for our API Gateway to invoke our function.
// However, we add the permissions to a specific Lambda alias from the matching stage
// in our API gateway. This ensures that we don't have dev routes invoking live functions etc.
resource "aws_lambda_permission" "api" {
  for_each = local.stages

  statement_id = format("Allow%sInvoke", title(each.key))
  action       = "lambda:InvokeFunction"
  principal    = "apigateway.amazonaws.com"

  function_name = aws_lambda_function.api_handler.function_name
  qualifier     = each.key

  source_arn = format("%s/*/*", aws_apigatewayv2_stage.stages[each.key].execution_arn)
}

// Output the latest version of our Lambda function. If we had more than one lambda
// we'd output a map here with the name and version as our key/value pairs.
// Due to the simplicity of this exercise, we'll just output the version number.
output "lambda_latest" {
  value = aws_lambda_function.api_handler.version
}

// For each of our lambda aliases, we'll output which specific version of the Lambda
// function our alias is pointing to. As above, this would likely be a map of multiple
// Lambda functions to versions, in a more realistic setting.
output "lambda_deployments" {
  value = {
    for k, v in aws_lambda_alias.stages :
    k => v.function_version
  }
}
