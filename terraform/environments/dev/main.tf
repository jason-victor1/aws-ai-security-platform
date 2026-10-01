terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project      = var.project_name
      Environment  = var.environment
      ManagedBy    = "Terraform"
      SecurityTier = "DeterministicControlPlane"
    }
  }
}

# Pillar 1: Ingress Gateway & Token Normalizer
module "ingress_gateway" {
  source       = "../../modules/01-ingress-gateway"
  project_name = var.project_name
  environment  = var.environment
}

# Pillar 2: RAG Datastore & Semantic Sanitizer
module "rag_datastore" {
  source       = "../../modules/02-rag-datastore"
  project_name = var.project_name
  environment  = var.environment
}

# Pillar 3: Model Supply-Chain Attestation & KMS Registry
module "model_registry" {
  source       = "../../modules/03-model-registry"
  project_name = var.project_name
  environment  = var.environment
}

# Pillar 4: Private Isolated Inference Fabric
module "inference_runtime" {
  source       = "../../modules/04-inference-runtime"
  project_name = var.project_name
  environment  = var.environment
}

# Pillar 5: Dynamic Non-Human Identity (STS Broker)
module "sts_broker" {
  source       = "../../modules/05-sts-broker"
  project_name = var.project_name
  environment  = var.environment
}

# Pillar 6: Firecracker Sandbox & Circuit Breaker
module "sandbox_circuit" {
  source              = "../../modules/06-sandbox-circuit"
  project_name        = var.project_name
  environment         = var.environment
  base_agent_role_arn = module.sts_broker.base_agent_role_arn
}
