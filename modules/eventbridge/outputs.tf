output "alarm_state_change_rule" {
  description = "Name of the CloudWatch alarm state change rule"
  value       = aws_cloudwatch_event_rule.alarm_state_change.name
}

output "alarm_to_lambda_rule" {
  description = "Name of the alarm to Lambda remediation rule"
  value       = aws_cloudwatch_event_rule.alarm_to_lambda.name
}

output "ssm_execution_status_rule" {
  description = "Name of the SSM execution status rule"
  value       = aws_cloudwatch_event_rule.ssm_execution_status.name
}

output "alarm_state_change_rule_arn" {
  description = "ARN of the CloudWatch alarm state change rule"
  value       = aws_cloudwatch_event_rule.alarm_state_change.arn
}
