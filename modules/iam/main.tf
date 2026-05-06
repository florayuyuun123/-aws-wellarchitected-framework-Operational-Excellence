locals {
  prefix = "chatops"
}

# ─────────────────────────────────────────
# Lambda Role
# ─────────────────────────────────────────
resource "aws_iam_role" "lambda" {
  name = "${local.prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_ssm" {
  name = "${local.prefix}-lambda-ssm-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMAccess"
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution",
          "ssm:ListDocuments",
          "ssm:DescribeDocument",
          "ssm:GetDocument"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2ReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ─────────────────────────────────────────
# SSM Role
# ─────────────────────────────────────────
resource "aws_iam_role" "ssm" {
  name = "${local.prefix}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ssm.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ssm_execution" {
  name = "${local.prefix}-ssm-execution-policy"
  role = aws_iam_role.ssm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Actions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# ─────────────────────────────────────────
# Chatbot Role
# ─────────────────────────────────────────
resource "aws_iam_role" "chatbot" {
  name = "${local.prefix}-chatbot-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "chatbot.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "chatbot_permissions" {
  name = "${local.prefix}-chatbot-policy"
  role = aws_iam_role.chatbot.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchRead"
        Effect = "Allow"
        Action = [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "LambdaInvoke"
        Effect = "Allow"
        Action = [
          "lambda:invokeFunction",
          "lambda:ListFunctions"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMRead"
        Effect = "Allow"
        Action = [
          "ssm:ListDocuments",
          "ssm:DescribeDocument",
          "ssm:GetDocument",
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = "*"
      }
    ]
  })
}
