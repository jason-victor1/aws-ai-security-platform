data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Archive the STS Broker Lambda source code
data "archive_file" "broker_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../src/sts_broker/broker.py"
  output_path = "${path.module}/broker_payload.zip"
}

# --- Base Agent Role (The role assumed with restricted session policies) ---
resource "aws_iam_role" "base_agent_role" {
  name = "${var.project_name}-${var.environment}-base-agent-role"

  # Trust policy: Only the STS Broker Lambda can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.broker_lambda_role.arn
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Baseline maximum permissions the agent can ever hold (pre-session attenuation)
resource "aws_iam_role_policy" "base_agent_policy" {
  name = "${var.project_name}-${var.environment}-base-agent-boundary"
  role = aws_iam_role.base_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PermitEcsServiceRestart"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Sid    = "PermitEc2Reboot"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:RebootInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "PermitS3RunbookRead"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::*-runbooks/*"
      }
    ]
  })
}

# --- STS Broker Lambda Execution Role ---
resource "aws_iam_role" "broker_lambda_role" {
  name = "${var.project_name}-${var.environment}-sts-broker-role"

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

# Allow Broker to write logs and assume the Base Agent Role
resource "aws_iam_role_policy" "broker_lambda_policy" {
  name = "${var.project_name}-${var.environment}-sts-broker-policy"
  role = aws_iam_role.broker_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "AssumeBaseAgentRole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = aws_iam_role.base_agent_role.arn
      }
    ]
  })
}

# --- STS Broker Lambda Function ---
resource "aws_lambda_function" "sts_broker" {
  function_name    = "${var.project_name}-${var.environment}-sts-broker"
  filename         = data.archive_file.broker_zip.output_path
  source_code_hash = data.archive_file.broker_zip.output_base64sha256
  handler          = "broker.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.broker_lambda_role.arn
  timeout          = 15
  memory_size      = 256

  environment {
    variables = {
      BASE_AGENT_ROLE_ARN = aws_iam_role.base_agent_role.arn
    }
  }
}
