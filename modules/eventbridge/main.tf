locals {
  prefix = var.prefix
}

# ─────────────────────────────────────────
# Rule 1: CloudWatch Alarm State Changes → SNS
# Catches any alarm transitioning to ALARM state
# SNS then delivers to Chatbot → Slack
# ─────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "alarm_state_change" {
  name        = "${local.prefix}-alarm-state-change"
  description = "Route CloudWatch alarm state changes to SNS for Slack delivery"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM", "OK"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "alarm_to_sns" {
  rule      = aws_cloudwatch_event_rule.alarm_state_change.name
  target_id = "AlarmToSNS"
  arn       = var.sns_topic_arn
}

# Allow EventBridge, CloudWatch and account root to publish to SNS
resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = var.sns_topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = var.sns_topic_arn
      },
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = var.sns_topic_arn
      },
      {
        Sid    = "AllowAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "sns:Publish"
        Resource = var.sns_topic_arn
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# ─────────────────────────────────────────
# Rule 2: CloudWatch Alarm ALARM state → Lambda
# Triggers Lambda directly for automated remediation
# ─────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "alarm_to_lambda" {
  name        = "${local.prefix}-alarm-to-lambda"
  description = "Trigger ChatOps Lambda on ALARM state for automated remediation"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "alarm_invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.alarm_to_lambda.name
  target_id = "AlarmInvokeLambda"
  arn       = var.lambda_function_arn
}

# ─────────────────────────────────────────
# Rule 3: SSM Automation Execution Status → SNS
# Notifies Slack when a runbook completes or fails
# ─────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "ssm_execution_status" {
  name        = "${local.prefix}-ssm-execution-status"
  description = "Route SSM automation execution results to Slack"

  event_pattern = jsonencode({
    source      = ["aws.ssm"]
    detail-type = ["EC2 Automation Execution Status-change Notification"]
    detail = {
      Status = ["Success", "Failed", "TimedOut", "Cancelled"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ssm_status_to_sns" {
  rule      = aws_cloudwatch_event_rule.ssm_execution_status.name
  target_id = "SSMStatusToSNS"
  arn       = var.sns_topic_arn
}
