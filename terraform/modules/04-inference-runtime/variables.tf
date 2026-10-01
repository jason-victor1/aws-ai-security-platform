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

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the isolated inference VPC"
  default     = "10.100.0.0/16"
}
