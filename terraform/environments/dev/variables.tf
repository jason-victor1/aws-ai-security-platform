variable "aws_region" {
  type        = string
  description = "AWS deployment region"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Project name prefix"
  default     = "ai-sec-platform"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
  default     = "dev"
}
