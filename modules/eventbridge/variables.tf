variable "prefix" {
  description = "Prefix for all EventBridge resource names"
  type        = string
  default     = "chatops"
}

variable "sns_topic_arn" {
  description = "SNS topic ARN to route alarm events to"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the ChatOps Lambda function"
  type        = string
}
