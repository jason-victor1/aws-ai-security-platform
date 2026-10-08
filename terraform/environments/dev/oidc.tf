# GitHub OIDC Identity Provider (data or resource)
data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # Standard GitHub OIDC thumbprint
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# IAM Role assumed by GitHub Actions
resource "aws_iam_role" "github_attestation_role" {
  name = "${var.project_name}-github-actions-attestation-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:jason-victor1/aws-ai-security-platform:*"
          }
        }
      }
    ]
  })
}

# KMS Signing & Verification Policy for Model Attestation
resource "aws_iam_role_policy" "github_attestation_kms" {
  name = "${var.project_name}-kms-sign-policy-${var.environment}"
  role = aws_iam_role.github_attestation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Sign",
          "kms:GetPublicKey",
          "kms:DescribeKey"
        ]
        Resource = module.model_registry.kms_key_arn
      }
    ]
  })
}

output "github_attestation_role_arn" {
  description = "IAM Role ARN to configure in GitHub Secrets (AWS_ATTESTATION_ROLE_ARN)"
  value       = aws_iam_role.github_attestation_role.arn
}

output "kms_model_signing_key_arn" {
  description = "KMS Key ARN to configure in GitHub Secrets (KMS_MODEL_SIGNING_KEY_ARN)"
  value       = module.model_registry.kms_key_arn
}
