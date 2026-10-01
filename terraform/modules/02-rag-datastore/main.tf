data "aws_caller_identity" "current" {}

data "archive_file" "sanitizer_zip" {
  type        = "zip"
  source_file = "${path.module}/../../../src/rag_sanitizer/sanitizer.py"
  output_path = "${path.module}/sanitizer_payload.zip"
}

# KMS Key for Runbook & Vector Storage
resource "aws_kms_key" "rag_key" {
  description             = "KMS Key for AI Runbook and Context Storage"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Encrypted S3 Bucket for Verified Runbooks
resource "aws_s3_bucket" "runbooks_bucket" {
  bucket        = "${var.project_name}-${var.environment}-runbooks-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "runbooks_encryption" {
  bucket = aws_s3_bucket.runbooks_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.rag_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "runbooks_block" {
  bucket                  = aws_s3_bucket.runbooks_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for Sanitizer Lambda
resource "aws_iam_role" "sanitizer_role" {
  name = "${var.project_name}-${var.environment}-rag-sanitizer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sanitizer_policy" {
  name = "${var.project_name}-${var.environment}-rag-sanitizer-policy"
  role = aws_iam_role.sanitizer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.runbooks_bucket.arn}/*"
      }
    ]
  })
}

# RAG Context Sanitizer Lambda Function
resource "aws_lambda_function" "rag_sanitizer" {
  function_name    = "${var.project_name}-${var.environment}-rag-sanitizer"
  filename         = data.archive_file.sanitizer_zip.output_path
  source_code_hash = data.archive_file.sanitizer_zip.output_base64sha256
  handler          = "sanitizer.handler"
  runtime          = "python3.11"
  role             = aws_iam_role.sanitizer_role.arn
  timeout          = 15
  memory_size      = 256

  environment {
    variables = {
      RUNBOOKS_BUCKET = aws_s3_bucket.runbooks_bucket.id
    }
  }
}
