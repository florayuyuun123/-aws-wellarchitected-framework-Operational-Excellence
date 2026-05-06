locals {
  prefix = var.prefix
}

# ═════════════════════════════════════════
# SERVERLESS DOCUMENTS — active by default
# No EC2 instances required
# ═════════════════════════════════════════

# ─────────────────────────────────────────
# Document 1: List Lambda Functions
# Triggered from Slack: see all Lambda functions and their state
# ─────────────────────────────────────────
resource "aws_ssm_document" "list_lambdas" {
  name            = "${local.prefix}-list-lambdas"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "List all Lambda functions and their runtime, state, and last modified date"
    assumeRole    = var.role_arn
    mainSteps = [{
      name   = "listFunctions"
      action = "aws:executeAwsApi"
      inputs = {
        Service = "lambda"
        Api     = "ListFunctions"
      }
      outputs = [{
        Name     = "Functions"
        Selector = "$.Functions"
        Type     = "MapList"
      }]
    }]
    outputs = ["listFunctions.Functions"]
  })
}

# ─────────────────────────────────────────
# Document 2: Check Lambda Health
# Triggered from Slack: get config and state of a specific function
# ─────────────────────────────────────────
resource "aws_ssm_document" "check_lambda_health" {
  name            = "${local.prefix}-check-lambda-health"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Get configuration and state of a specific Lambda function"
    assumeRole    = var.role_arn
    parameters = {
      FunctionName = {
        type        = "String"
        description = "The Lambda function name to check"
      }
    }
    mainSteps = [{
      name   = "getFunction"
      action = "aws:executeAwsApi"
      inputs = {
        Service      = "lambda"
        Api          = "GetFunction"
        FunctionName = "{{ FunctionName }}"
      }
      outputs = [
        {
          Name     = "FunctionArn"
          Selector = "$.Configuration.FunctionArn"
          Type     = "String"
        },
        {
          Name     = "State"
          Selector = "$.Configuration.State"
          Type     = "String"
        },
        {
          Name     = "Runtime"
          Selector = "$.Configuration.Runtime"
          Type     = "String"
        }
      ]
    }]
    outputs = [
      "getFunction.FunctionArn",
      "getFunction.State",
      "getFunction.Runtime"
    ]
  })
}

# ─────────────────────────────────────────
# Document 3: List CloudWatch Alarms in ALARM state
# Triggered from Slack: see what is currently firing
# ─────────────────────────────────────────
resource "aws_ssm_document" "list_active_alarms" {
  name            = "${local.prefix}-list-active-alarms"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "List all CloudWatch alarms currently in ALARM state"
    assumeRole    = var.role_arn
    mainSteps = [{
      name   = "describeAlarms"
      action = "aws:executeAwsApi"
      inputs = {
        Service     = "cloudwatch"
        Api         = "DescribeAlarms"
        StateValue  = "ALARM"
      }
      outputs = [{
        Name     = "MetricAlarms"
        Selector = "$.MetricAlarms"
        Type     = "MapList"
      }]
    }]
    outputs = ["describeAlarms.MetricAlarms"]
  })
}

# ─────────────────────────────────────────
# Document 4: List SNS Topic Subscriptions
# Triggered from Slack: verify Chatbot is still subscribed
# ─────────────────────────────────────────
resource "aws_ssm_document" "list_sns_subscriptions" {
  name            = "${local.prefix}-list-sns-subscriptions"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "List all subscriptions for the ChatOps SNS alerts topic"
    assumeRole    = var.role_arn
    parameters = {
      TopicArn = {
        type        = "String"
        description = "The SNS topic ARN to inspect"
      }
    }
    mainSteps = [{
      name   = "listSubscriptions"
      action = "aws:executeAwsApi"
      inputs = {
        Service  = "sns"
        Api      = "ListSubscriptionsByTopic"
        TopicArn = "{{ TopicArn }}"
      }
      outputs = [{
        Name     = "Subscriptions"
        Selector = "$.Subscriptions"
        Type     = "MapList"
      }]
    }]
    outputs = ["listSubscriptions.Subscriptions"]
  })
}

# ═════════════════════════════════════════
# EC2 DOCUMENTS — disabled by default
# Set enable_ec2_documents = true in variables
# when you have EC2 instances to manage
# ═════════════════════════════════════════

# ─────────────────────────────────────────
# Document 5: Describe EC2 Instances
# ─────────────────────────────────────────
resource "aws_ssm_document" "describe_instances" {
  count           = var.enable_ec2_documents ? 1 : 0
  name            = "${local.prefix}-describe-instances"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "List all EC2 instances and their current state"
    assumeRole    = var.role_arn
    mainSteps = [{
      name   = "describeInstances"
      action = "aws:executeAwsApi"
      inputs = {
        Service = "ec2"
        Api     = "DescribeInstances"
        Filters = [{
          Name   = "instance-state-name"
          Values = ["running", "stopped", "pending"]
        }]
      }
      outputs = [{
        Name     = "Reservations"
        Selector = "$.Reservations"
        Type     = "MapList"
      }]
    }]
    outputs = ["describeInstances.Reservations"]
  })
}

# ─────────────────────────────────────────
# Document 6: Stop EC2 Instance
# ─────────────────────────────────────────
resource "aws_ssm_document" "stop_instance" {
  count           = var.enable_ec2_documents ? 1 : 0
  name            = "${local.prefix}-stop-instance"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Stop a specific EC2 instance by instance ID"
    assumeRole    = var.role_arn
    parameters = {
      InstanceId = {
        type        = "String"
        description = "The EC2 instance ID to stop"
      }
    }
    mainSteps = [{
      name   = "stopInstance"
      action = "aws:executeAwsApi"
      inputs = {
        Service     = "ec2"
        Api         = "StopInstances"
        InstanceIds = ["{{ InstanceId }}"]
      }
    }]
  })
}

# ─────────────────────────────────────────
# Document 7: Restart EC2 Instance
# ─────────────────────────────────────────
resource "aws_ssm_document" "restart_instance" {
  count           = var.enable_ec2_documents ? 1 : 0
  name            = "${local.prefix}-restart-instance"
  document_type   = "Automation"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Reboot a specific EC2 instance by instance ID"
    assumeRole    = var.role_arn
    parameters = {
      InstanceId = {
        type        = "String"
        description = "The EC2 instance ID to reboot"
      }
    }
    mainSteps = [{
      name   = "rebootInstance"
      action = "aws:executeAwsApi"
      inputs = {
        Service     = "ec2"
        Api         = "RebootInstances"
        InstanceIds = ["{{ InstanceId }}"]
      }
    }]
  })
}
