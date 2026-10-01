output "model_registry_bucket_name" {
  description = "Name of the Model Registry S3 Bucket"
  value       = aws_s3_bucket.model_registry.id
}

output "model_registry_bucket_arn" {
  description = "ARN of the Model Registry S3 Bucket"
  value       = aws_s3_bucket.model_registry.arn
}

output "model_signing_key_arn" {
  description = "ARN of the Asymmetric KMS Model Signing Key"
  value       = aws_kms_key.model_signing_key.arn
}
