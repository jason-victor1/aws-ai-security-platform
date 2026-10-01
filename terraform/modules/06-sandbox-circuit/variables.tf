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

variable "base_agent_role_arn" {
  type        = string
  description = "ARN of the Base Agent Role to quarantine upon circuit breaker trip"
}
