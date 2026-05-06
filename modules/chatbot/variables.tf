variable "prefix" {
  description = "Prefix for all Chatbot resource names"
  type        = string
  default     = "chatops"
}

variable "role_arn" {
  description = "IAM role ARN for AWS Chatbot"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN that Chatbot subscribes to"
  type        = string
}

variable "slack_workspace_id" {
  description = "Slack workspace ID from AWS Chatbot console (complete OAuth first)"
  type        = string
}

variable "slack_channel_id" {
  description = "Slack channel ID where alerts will be posted"
  type        = string
}

variable "logging_level" {
  description = "Chatbot logging level: ERROR, INFO, or NONE"
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["ERROR", "INFO", "NONE"], var.logging_level)
    error_message = "logging_level must be ERROR, INFO, or NONE."
  }
}

variable "guardrail_policy_arns" {
  description = "List of IAM policy ARNs to use as guardrails limiting Chatbot command scope"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess"
  ]
}
