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
