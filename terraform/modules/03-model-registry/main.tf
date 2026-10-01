data "aws_caller_identity" "current" {}

# Asymmetric KMS Key for Cosign Digital Signatures
resource "aws_kms_key" "model_signing_key" {
  description              = "Asymmetric KMS Key for Cosign Model Weight Digital Signatures"
  customer_master_key_spec = "ECC_NIST_P256"
  key_usage                = "SIGN_VERIFY"
  deletion_window_in_days  = 7
}

resource "aws_kms_alias" "model_signing_key_alias" {
  name          = "alias/${var.project_name}-${var.environment}-model-signer"
  target_key_id = aws_kms_key.model_signing_key.key_id
}

# Symmetric KMS Key for Model Storage S3 Encryption
resource "aws_kms_key" "model_storage_key" {
  description             = "Symmetric KMS Key for S3 Model Checkpoint At-Rest Encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# KMS-Encrypted S3 Registry for Verified Model Weights
resource "aws_s3_bucket" "model_registry" {
  bucket        = "${var.project_name}-${var.environment}-model-registry-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "model_registry_versioning" {
  bucket = aws_s3_bucket.model_registry.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "model_registry_encryption" {
  bucket = aws_s3_bucket.model_registry.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.model_storage_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "model_registry_block" {
  bucket                  = aws_s3_bucket.model_registry.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
