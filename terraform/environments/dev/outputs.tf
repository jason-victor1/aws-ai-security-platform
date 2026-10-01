# Pillar 1: Ingress
output "api_gateway_endpoint" {
  description = "Public API Gateway URL for token normalization"
  value       = module.ingress_gateway.api_endpoint
}

# Pillar 2: RAG
output "runbooks_bucket_name" {
  description = "KMS-encrypted S3 Bucket for authenticated runbooks"
  value       = module.rag_datastore.runbooks_bucket_name
}

# Pillar 3: Model Supply Chain
output "model_registry_bucket_name" {
  description = "S3 Model Registry Bucket for verified model weights"
  value       = module.model_registry.model_registry_bucket_name
}

output "model_signing_key_arn" {
  description = "Asymmetric KMS Key for Cosign model signatures"
  value       = module.model_registry.model_signing_key_arn
}

# Pillar 4: Inference Fabric
output "inference_vpc_id" {
  description = "Isolated Inference VPC with zero internet egress"
  value       = module.inference_runtime.inference_vpc_id
}

output "inference_subnet_id" {
  description = "Air-gapped inference subnet"
  value       = module.inference_runtime.inference_subnet_id
}

# Pillar 5: Identity
output "sts_broker_lambda_arn" {
  description = "ARN of the STS Broker Lambda"
  value       = module.sts_broker.broker_lambda_arn
}

# Pillar 6: Sandboxing
output "sandbox_runner_lambda_arn" {
  description = "ARN of the Firecracker Sandbox Runner Lambda"
  value       = module.sandbox_circuit.sandbox_runner_lambda_arn
}

output "security_event_bus_name" {
  description = "Name of the security EventBridge bus"
  value       = module.sandbox_circuit.security_event_bus_name
}
