data "aws_region" "current" {}

# Isolated Inference VPC (No Internet Gateway, No NAT Gateway)
resource "aws_vpc" "inference_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-inference-vpc"
  }
}

# Air-Gapped Private Subnet (Strict internal communication only)
resource "aws_subnet" "isolated_subnet_a" {
  vpc_id            = aws_vpc.inference_vpc.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "${data.aws_region.current.name}a"

  tags = {
    Name = "${var.project_name}-${var.environment}-isolated-subnet-a"
  }
}

# Security Group: Inference Serving Runtime
resource "aws_security_group" "inference_sg" {
  name        = "${var.project_name}-${var.environment}-inference-sg"
  description = "Strict security group for model serving runtime (zero public ingress)"
  vpc_id      = aws_vpc.inference_vpc.id

  # Ingress: Allow serving port (8000) only from internal VPC CIDR
  ingress {
    description = "Internal inference requests"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Egress: Deny all arbitrary internet egress, only allow internal VPC traffic
  egress {
    description = "Internal VPC egress only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-inference-sg"
  }
}

# VPC Gateway Endpoint for S3 (Allows pulling signed models without traversing the internet)
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.inference_vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${var.project_name}-${var.environment}-s3-vpc-endpoint"
  }
}
