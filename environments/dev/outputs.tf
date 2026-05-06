output "cloudfront_dashboard_url" {
  description = "URL of the optional operations dashboard"
  value       = module.dashboard.cloudfront_url
}

output "lambda_function_arn" {
  description = "ARN of the ChatOps Lambda function"
  value       = module.lambda.function_arn
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.cloudwatch.sns_topic_arn
}

output "chatbot_configuration_arn" {
  description = "ARN of the AWS Chatbot Slack channel configuration"
  value       = module.chatbot.configuration_arn
  sensitive   = true
}

output "chatbot_slack_configured" {
  description = "Whether Slack integration is active"
  value       = nonsensitive(module.chatbot.slack_configured)
}
