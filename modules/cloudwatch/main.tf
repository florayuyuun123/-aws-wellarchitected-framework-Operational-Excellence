locals {
  prefix = var.prefix
}

# ─────────────────────────────────────────
# SNS Topic — receives all alarm notifications
# subscribed to by AWS Chatbot (Step 6)
# ─────────────────────────────────────────
resource "aws_sns_topic" "alerts" {
  name = "${local.prefix}-alerts"
}

# ─────────────────────────────────────────
# Alarm 1: Lambda Errors
# Triggers when the function throws any error
# ─────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.prefix}-lambda-errors"
  alarm_description   = "ChatOps Lambda function is throwing errors"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  period              = var.alarm_period_seconds
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.lambda_error_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ─────────────────────────────────────────
# Alarm 2: Lambda Duration
# Triggers when function runs close to timeout
# ─────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${local.prefix}-lambda-duration"
  alarm_description   = "ChatOps Lambda function duration is too high"
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  statistic           = "Maximum"
  period              = var.alarm_period_seconds
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.lambda_duration_threshold_ms
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ─────────────────────────────────────────
# Alarm 3: Lambda Throttles
# Triggers when Lambda is being throttled
# ─────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${local.prefix}-lambda-throttles"
  alarm_description   = "ChatOps Lambda function is being throttled"
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  statistic           = "Sum"
  period              = var.alarm_period_seconds
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.lambda_throttle_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ─────────────────────────────────────────
# Alarm 4: Lambda Concurrent Executions
# Triggers when concurrency is unusually high
# ─────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "lambda_concurrency" {
  alarm_name          = "${local.prefix}-lambda-concurrency"
  alarm_description   = "ChatOps Lambda concurrent executions are unusually high"
  namespace           = "AWS/Lambda"
  metric_name         = "ConcurrentExecutions"
  statistic           = "Maximum"
  period              = var.alarm_period_seconds
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = 10
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ─────────────────────────────────────────
# Composite Alarm — fires when errors AND throttles occur together
# Reduces noise by combining related alarms
# ─────────────────────────────────────────
resource "aws_cloudwatch_composite_alarm" "lambda_critical" {
  alarm_name        = "${local.prefix}-lambda-critical"
  alarm_description = "Critical: Lambda is both erroring and throttling simultaneously"

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.lambda_errors.alarm_name}) AND ALARM(${aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name})"

  alarm_actions = [aws_sns_topic.alerts.arn]
}
