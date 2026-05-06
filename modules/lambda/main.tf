locals {
  prefix      = var.prefix
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/chatops_lambda.zip"
}

# ─────────────────────────────────────────
# Package Lambda source into zip
# ─────────────────────────────────────────
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = local.output_path
}

# ─────────────────────────────────────────
# CloudWatch Log Group (created before function)
# ─────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.prefix}-chatops-handler"
  retention_in_days = 14
}

# ─────────────────────────────────────────
# Lambda Function
# ─────────────────────────────────────────
resource "aws_lambda_function" "chatops" {
  function_name    = "${local.prefix}-chatops-handler"
  description      = "Handles ChatOps commands from Slack via AWS Chatbot"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = var.role_arn
  handler          = "handler.lambda_handler"
  runtime          = var.runtime
  timeout          = var.timeout

  environment {
    variables = {
      # Serverless — always active
      SSM_LIST_LAMBDAS           = var.ssm_list_lambdas
      SSM_CHECK_LAMBDA_HEALTH    = var.ssm_check_lambda_health
      SSM_LIST_ACTIVE_ALARMS     = var.ssm_list_active_alarms
      SSM_LIST_SNS_SUBSCRIPTIONS = var.ssm_list_sns_subscriptions
      # EC2 — "ec2-documents-disabled" until enable_ec2_documents = true
      SSM_DESCRIBE_INSTANCES     = var.ssm_describe_instances
      SSM_STOP_INSTANCE          = var.ssm_stop_instance
      SSM_RESTART_INSTANCE       = var.ssm_restart_instance
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

# ─────────────────────────────────────────
# Allow EventBridge to invoke this Lambda
# ─────────────────────────────────────────
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chatops.function_name
  principal     = "events.amazonaws.com"
}
