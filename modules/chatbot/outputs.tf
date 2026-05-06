output "configuration_arn" {
  description = "ARN of the AWS Chatbot Slack channel configuration (empty if Slack IDs not yet set)"
  value       = local.slack_configured ? awscc_chatbot_slack_channel_configuration.this[0].arn : "chatbot-not-yet-configured"
}

output "configuration_name" {
  description = "Name of the AWS Chatbot Slack channel configuration"
  value       = local.slack_configured ? awscc_chatbot_slack_channel_configuration.this[0].configuration_name : "chatbot-not-yet-configured"
}

output "slack_configured" {
  description = "Whether the Slack integration has been configured"
  value       = nonsensitive(local.slack_configured)
}

output "log_group_name" {
  description = "CloudWatch log group for Chatbot activity"
  value       = aws_cloudwatch_log_group.chatbot.name
}
