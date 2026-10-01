data "archive_file" "gateway_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../src/gateway/handler.py"
  output_path = "${path.module}/gateway_payload.zip"
}

# IAM Execution Role for Ingress Lambda
resource "aws_iam_role" "ingress_role" {
  name = "${var.project_name}-${var.environment}-ingress-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ingress_logging" {
  name = "${var.project_name}-${var.environment}-ingress-logging"
  role = aws_iam_role.ingress_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

# Token Normalization Ingress Lambda
resource "aws_lambda_function" "ingress_proxy" {
  function_name    = "${var.project_name}-${var.environment}-ingress-proxy"
  filename         = data.archive_file.gateway_zip.output_path
  source_code_hash = data.archive_file.gateway_zip.output_base64sha256
  handler          = "handler.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.ingress_role.arn
  timeout          = 10
  memory_size      = 256
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-${var.environment}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.ingress_proxy.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "remediate_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /api/v1/remediate"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingress_proxy.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
