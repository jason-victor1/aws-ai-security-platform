output "api_endpoint" {
  description = "Public API Gateway URL"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "ingress_lambda_arn" {
  description = "ARN of Ingress Token Proxy Lambda"
  value       = aws_lambda_function.ingress_proxy.arn
}
