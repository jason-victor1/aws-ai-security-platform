output "sandbox_runner_lambda_arn" {
  description = "ARN of the Sandbox Runner Lambda"
  value       = aws_lambda_function.sandbox_runner.arn
}

output "sandbox_runner_lambda_name" {
  description = "Name of the Sandbox Runner Lambda"
  value       = aws_lambda_function.sandbox_runner.function_name
}

output "security_event_bus_name" {
  description = "Name of the security EventBridge bus"
  value       = aws_cloudwatch_event_bus.security_bus.name
}
