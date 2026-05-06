variable "role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "prefix" {
  description = "Prefix for all Lambda resource names"
  type        = string
  default     = "chatops"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

# ─── Serverless SSM document names ───
variable "ssm_list_lambdas" {
  description = "SSM document name for list-lambdas"
  type        = string
  default     = "chatops-list-lambdas"
}

variable "ssm_check_lambda_health" {
  description = "SSM document name for check-lambda-health"
  type        = string
  default     = "chatops-check-lambda-health"
}

variable "ssm_list_active_alarms" {
  description = "SSM document name for list-active-alarms"
  type        = string
  default     = "chatops-list-active-alarms"
}

variable "ssm_list_sns_subscriptions" {
  description = "SSM document name for list-sns-subscriptions"
  type        = string
  default     = "chatops-list-sns-subscriptions"
}

# ─── EC2 SSM document names (used only when enable_ec2_documents = true) ───
variable "ssm_describe_instances" {
  description = "SSM document name for describe-instances (EC2)"
  type        = string
  default     = "ec2-documents-disabled"
}

variable "ssm_stop_instance" {
  description = "SSM document name for stop-instance (EC2)"
  type        = string
  default     = "ec2-documents-disabled"
}

variable "ssm_restart_instance" {
  description = "SSM document name for restart-instance (EC2)"
  type        = string
  default     = "ec2-documents-disabled"
}
