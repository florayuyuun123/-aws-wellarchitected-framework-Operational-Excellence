variable "prefix" {
  description = "Prefix for all CloudWatch resource names"
  type        = string
  default     = "chatops"
}

variable "lambda_function_name" {
  description = "Name of the ChatOps Lambda function to monitor"
  type        = string
}

variable "lambda_error_threshold" {
  description = "Number of Lambda errors to trigger alarm"
  type        = number
  default     = 1
}

variable "lambda_duration_threshold_ms" {
  description = "Lambda duration threshold in milliseconds to trigger alarm"
  type        = number
  default     = 50000
}

variable "lambda_throttle_threshold" {
  description = "Number of Lambda throttles to trigger alarm"
  type        = number
  default     = 1
}

variable "alarm_evaluation_periods" {
  description = "Number of periods to evaluate before triggering alarm"
  type        = number
  default     = 1
}

variable "alarm_period_seconds" {
  description = "Period in seconds for each evaluation window"
  type        = number
  default     = 60
}
