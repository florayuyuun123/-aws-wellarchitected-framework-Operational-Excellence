variable "prefix" {
  description = "Prefix for all dashboard resource names"
  type        = string
  default     = "chatops"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
