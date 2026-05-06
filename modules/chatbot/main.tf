locals {
  prefix          = var.prefix
  slack_configured = var.slack_workspace_id != "" && var.slack_channel_id != ""
}

# ─────────────────────────────────────────
# Slack Workspace Association
# Requires manual OAuth step first — see DOCUMENTATION.md Step 6
# Only deploys when both slack_workspace_id and slack_channel_id are set
# ─────────────────────────────────────────
resource "awscc_chatbot_slack_channel_configuration" "this" {
  count = local.slack_configured ? 1 : 0

  configuration_name = "${local.prefix}-slack-channel"
  iam_role_arn       = var.role_arn
  slack_workspace_id = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
  logging_level      = var.logging_level

  sns_topic_arns = [var.sns_topic_arn]

  guardrail_policies = var.guardrail_policy_arns

  user_role_required = false
}

# ─────────────────────────────────────────
# CloudWatch Log Group for Chatbot activity
# ─────────────────────────────────────────
resource "aws_cloudwatch_log_group" "chatbot" {
  name              = "/aws/chatbot/${local.prefix}"
  retention_in_days = 14
}
