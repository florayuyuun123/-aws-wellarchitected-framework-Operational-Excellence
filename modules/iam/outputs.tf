output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda.name
}

output "ssm_role_arn" {
  description = "ARN of the SSM execution role"
  value       = aws_iam_role.ssm.arn
}

output "ssm_role_name" {
  description = "Name of the SSM execution role"
  value       = aws_iam_role.ssm.name
}

output "chatbot_role_arn" {
  description = "ARN of the Chatbot role"
  value       = aws_iam_role.chatbot.arn
}

output "chatbot_role_name" {
  description = "Name of the Chatbot role"
  value       = aws_iam_role.chatbot.name
}
