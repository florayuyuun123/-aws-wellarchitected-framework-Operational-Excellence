variable "role_arn" {
  description = "IAM role ARN for SSM automation execution"
  type        = string
}

variable "prefix" {
  description = "Prefix for all SSM resource names"
  type        = string
  default     = "chatops"
}

variable "enable_ec2_documents" {
  description = "Set to true when you have EC2 instances to manage. Deploys describe, stop, and restart documents."
  type        = bool
  default     = false
}
