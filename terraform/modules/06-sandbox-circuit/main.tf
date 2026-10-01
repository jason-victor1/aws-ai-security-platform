data "archive_file" "runner_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../src/sandbox_runner/executor.py"
  output_path = "${path.module}/runner_payload.zip"
}

# --- Sandbox Runner Execution Role ---
# CRITICAL: This role has NO permissions to execute AWS actions against infrastructure.
# It only has permission to send logs. All AWS API calls are authenticated using
# the ephemeral STS credentials passed into the function per execution.
resource "aws_iam_role" "sandbox_runner_role" {
  name = "${var.project_name}-${var.environment}-sandbox-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "sandbox_runner_logging" {
  name = "${var.project_name}-${var.environment}-sandbox-runner-logging"
  role = aws_iam_role.sandbox_runner_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# --- Sandbox Runner Lambda (Firecracker MicroVM) ---
resource "aws_lambda_function" "sandbox_runner" {
  function_name    = "${var.project_name}-${var.environment}-sandbox-runner"
  filename         = data.archive_file.runner_zip.output_path
  source_code_hash = data.archive_file.runner_zip.output_base64sha256
  handler          = "executor.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.sandbox_runner_role.arn
  timeout          = 30
  memory_size      = 256
}

# --- EventBridge Circuit Breaker Kill-Switch ---
resource "aws_cloudwatch_event_bus" "security_bus" {
  name = "${var.project_name}-${var.environment}-security-bus"
}

# EventBridge rule that catches "AgentRunawayLoop" or "SecurityBreachTrigger"
resource "aws_cloudwatch_event_rule" "kill_switch_rule" {
  name           = "${var.project_name}-${var.environment}-agent-kill-switch"
  event_bus_name = aws_cloudwatch_event_bus.security_bus.name
  description    = "Detects runaway loops or policy trips and executes immediate containment"

  event_pattern = jsonencode({
    source      = ["ai.security.circuitbreaker"]
    detail-type = ["CircuitBreakerTrip"]
  })
}
