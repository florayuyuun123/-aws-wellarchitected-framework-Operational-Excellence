output "function_arn" {
  description = "ARN of the ChatOps Lambda function"
  value       = aws_lambda_function.chatops.arn
}

output "function_name" {
  description = "Name of the ChatOps Lambda function"
  value       = aws_lambda_function.chatops.function_name
}

output "invoke_arn" {
  description = "Invoke ARN of the ChatOps Lambda function"
  value       = aws_lambda_function.chatops.invoke_arn
}

output "log_group_name" {
  description = "CloudWatch log group name for the Lambda function"
  value       = aws_cloudwatch_log_group.lambda.name
}
