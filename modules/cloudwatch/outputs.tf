output "sns_topic_arn" {
  description = "ARN of the SNS alerts topic"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS alerts topic"
  value       = aws_sns_topic.alerts.name
}

output "alarm_lambda_errors" {
  description = "Name of the Lambda errors alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.alarm_name
}

output "alarm_lambda_duration" {
  description = "Name of the Lambda duration alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_duration.alarm_name
}

output "alarm_lambda_throttles" {
  description = "Name of the Lambda throttles alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name
}

output "alarm_lambda_concurrency" {
  description = "Name of the Lambda concurrency alarm"
  value       = aws_cloudwatch_metric_alarm.lambda_concurrency.alarm_name
}

output "composite_alarm_name" {
  description = "Name of the composite critical alarm"
  value       = aws_cloudwatch_composite_alarm.lambda_critical.alarm_name
}
