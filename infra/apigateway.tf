resource "aws_apigatewayv2_api" "mover_api" {
  name          = "mover_api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["http://localhost:5173"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "movers_lambda_integration" {
  api_id           = aws_apigatewayv2_api.mover_api.id
  integration_type = "AWS_PROXY"
  integration_method        = "POST"
  integration_uri           = aws_lambda_function.retrieve_week_lambda.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_movers_route" {
  api_id    = aws_apigatewayv2_api.mover_api.id
  route_key = "GET /movers"
  target = "integrations/${aws_apigatewayv2_integration.movers_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.mover_api.id
  name   = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_retrieval" {
  statement_id  = "AllowAPIGatewayInvokeRetrieval"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retrieve_week_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.mover_api.execution_arn}/*/*"
}