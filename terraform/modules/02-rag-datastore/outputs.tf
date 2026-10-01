output "runbooks_bucket_arn" {
  description = "ARN of the S3 Runbooks bucket"
  value       = aws_s3_bucket.runbooks_bucket.arn
}

output "runbooks_bucket_name" {
  description = "Name of the S3 Runbooks bucket"
  value       = aws_s3_bucket.runbooks_bucket.id
}

output "rag_sanitizer_lambda_arn" {
  description = "ARN of the RAG Sanitizer Lambda"
  value       = aws_lambda_function.rag_sanitizer.arn
}
