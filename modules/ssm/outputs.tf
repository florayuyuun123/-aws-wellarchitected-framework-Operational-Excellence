# ─── Serverless documents (always available) ───
output "list_lambdas_doc" {
  description = "Name of the list-lambdas SSM document"
  value       = aws_ssm_document.list_lambdas.name
}

output "check_lambda_health_doc" {
  description = "Name of the check-lambda-health SSM document"
  value       = aws_ssm_document.check_lambda_health.name
}

output "list_active_alarms_doc" {
  description = "Name of the list-active-alarms SSM document"
  value       = aws_ssm_document.list_active_alarms.name
}

output "list_sns_subscriptions_doc" {
  description = "Name of the list-sns-subscriptions SSM document"
  value       = aws_ssm_document.list_sns_subscriptions.name
}

# ─── EC2 documents (only when enable_ec2_documents = true) ───
output "describe_instances_doc" {
  description = "Name of the describe-instances SSM document (EC2 only)"
  value       = var.enable_ec2_documents ? aws_ssm_document.describe_instances[0].name : "ec2-documents-disabled"
}

output "stop_instance_doc" {
  description = "Name of the stop-instance SSM document (EC2 only)"
  value       = var.enable_ec2_documents ? aws_ssm_document.stop_instance[0].name : "ec2-documents-disabled"
}

output "restart_instance_doc" {
  description = "Name of the restart-instance SSM document (EC2 only)"
  value       = var.enable_ec2_documents ? aws_ssm_document.restart_instance[0].name : "ec2-documents-disabled"
}

output "all_document_names" {
  description = "List of all currently deployed SSM document names"
  value = concat(
    [
      aws_ssm_document.list_lambdas.name,
      aws_ssm_document.check_lambda_health.name,
      aws_ssm_document.list_active_alarms.name,
      aws_ssm_document.list_sns_subscriptions.name,
    ],
    var.enable_ec2_documents ? [
      aws_ssm_document.describe_instances[0].name,
      aws_ssm_document.stop_instance[0].name,
      aws_ssm_document.restart_instance[0].name,
    ] : []
  )
}
