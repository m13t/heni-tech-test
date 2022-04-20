// Creates our API Gateway - V2 HTTP type
resource "aws_apigatewayv2_api" "api" {
  name          = "demo-api"
  protocol_type = "HTTP"

  tags = {
    Name = "DEMO API"
  }
}

// Create gateway stages for each stage defined in our `config.tf` file.
// Each stage is an point-in-time representation of the API gateway configuraiton
// as well as stage specific configuration. For `dev` we automatically deploy changes
// immediately, for test and live, we set the deployment ID in the config and then apply.
resource "aws_apigatewayv2_stage" "stages" {
  for_each = local.stages

  api_id = aws_apigatewayv2_api.api.id
  name   = each.key

  // Simple lookups with fallbacks in case missing from config
  auto_deploy   = lookup(each.value, "automatic", false)
  deployment_id = lookup(each.value, "deployment_id", null)

  // Here we set our stage specific configuration. We can pass this to our integrations
  // to ensure that the `dev` stage calls the `dev` lambda alias.
  stage_variables = {
    lambdaAlias = each.key
  }
}

// Create an integration for our Lambda function. Here we reference our Lambda function
// alias that we created in `lambda.tf`, and pass in our stage specific configuration in
// order to ensure the correct Lambda function is called for the correct stage.
resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.api.id

  integration_type = "AWS_PROXY"
  integration_uri = format(
    "%s:$${stageVariables.lambdaAlias}",
    aws_lambda_function.api_handler.arn,
  )

  payload_format_version = "2.0"
}

// Create a route matching `/` and point to our Lambda integration.
resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /"

  target = format(
    "integrations/%s",
    aws_apigatewayv2_integration.lambda.id,
  )
}

// Create a route matching '/build-info' and point to our Lambda integration.
resource "aws_apigatewayv2_route" "info" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /build-info"

  target = format(
    "integrations/%s",
    aws_apigatewayv2_integration.lambda.id,
  )
}

// For each of our API Gateway stages that we've defined in `config.tf`, we output
// a map of our stage name to the deployment ID.
output "api_deployments" {
  value = {
    for k, v in aws_apigatewayv2_stage.stages :
    k => v.deployment_id
  }
}
