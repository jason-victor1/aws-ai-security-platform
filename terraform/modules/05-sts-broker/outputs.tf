output "broker_lambda_arn" {
  description = "ARN of the STS Broker Lambda"
  value       = aws_lambda_function.sts_broker.arn
}

output "broker_lambda_name" {
  description = "Name of the STS Broker Lambda"
  value       = aws_lambda_function.sts_broker.function_name
}

output "base_agent_role_arn" {
  description = "ARN of the Base Agent IAM Role"
  value       = aws_iam_role.base_agent_role.arn
}
