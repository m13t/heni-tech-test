resource "aws_apigatewayv2_api" "api" {
  name          = "demo-api"
  protocol_type = "HTTP"

  tags = {
    Name = "DEMO API"
  }
}

resource "aws_apigatewayv2_stage" "stages" {
  for_each = local.stages

  api_id = aws_apigatewayv2_api.api.id
  name   = each.key

  auto_deploy   = lookup(each.value, "automatic", false)
  deployment_id = lookup(each.value, "deployment_id", null)

  stage_variables = {
    lambdaAlias = each.key
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id = aws_apigatewayv2_api.api.id

  integration_type = "AWS_PROXY"
  integration_uri = format(
    "%s:$${stageVariables.lambdaAlias}",
    aws_lambda_function.api_handler.arn,
  )

  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /"

  target = format(
    "integrations/%s",
    aws_apigatewayv2_integration.lambda.id,
  )
}

resource "aws_apigatewayv2_route" "info" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /build-info"

  target = format(
    "integrations/%s",
    aws_apigatewayv2_integration.lambda.id,
  )
}

output "api_deployments" {
  value = {
    for k, v in aws_apigatewayv2_stage.stages :
    k => v.deployment_id
  }
}
