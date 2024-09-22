resource "aws_api_gateway_rest_api" "currency-api" {
    name = "${var.environment}-currency-api"
}

resource "aws_api_gateway_resource" "max_price_resource" {
  rest_api_id = aws_api_gateway_rest_api.currency-api.id
  parent_id   = aws_api_gateway_rest_api.currency-api.root_resource_id
  path_part   = "max_price"
}

resource "aws_api_gateway_method" "get-method" {
  rest_api_id   = aws_api_gateway_rest_api.currency-api.id
  resource_id   = aws_api_gateway_resource.max_price_resource.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true  #ask for an API key to be present.
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.currency-api.id
  resource_id             = aws_api_gateway_resource.max_price_resource.id
  http_method             = aws_api_gateway_method.get-method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.integration_uri
}


resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com" 

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.currency-api.execution_arn}/*/*/*"
}


resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.integration , aws_api_gateway_method.get-method]
  rest_api_id = aws_api_gateway_rest_api.currency-api.id
  
  lifecycle {
    create_before_destroy = true
  }

  triggers = {
    redeploy = filebase64sha256("main.tf")  # this path refers to this TerraForm source file
  }
}

resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.currency-api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
}
   

#adding usage plan and attached API key

resource "aws_api_gateway_api_key" "stream-API-key" {
  name    = "${var.environment}-stream-API-key"
}

resource "aws_api_gateway_usage_plan" "stream-usage-plan" {
  name        = "${var.environment}-stream-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.currency-api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  quota_settings {
    limit  = var.quota_limit
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = var.burst_limit
    rate_limit  = var.rate_limit
  }

  depends_on = [
    aws_api_gateway_deployment.deployment,
    aws_api_gateway_api_key.stream-API-key
  ]
}

resource "aws_api_gateway_usage_plan_key" "stream-usage-plan-key" {
  key_id        = aws_api_gateway_api_key.stream-API-key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.stream-usage-plan.id
  depends_on    = [
    aws_api_gateway_usage_plan.stream-usage-plan,
    aws_api_gateway_api_key.stream-API-key
  ]
}