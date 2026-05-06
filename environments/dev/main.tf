terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "awscc" {
  region = var.aws_region
}

module "iam" {
  source = "../../modules/iam"
}

module "ssm" {
  source               = "../../modules/ssm"
  role_arn             = module.iam.ssm_role_arn
  enable_ec2_documents = var.enable_ec2_documents
}

module "lambda" {
  source                     = "../../modules/lambda"
  role_arn                   = module.iam.lambda_role_arn
  # Serverless — always wired
  ssm_list_lambdas           = module.ssm.list_lambdas_doc
  ssm_check_lambda_health    = module.ssm.check_lambda_health_doc
  ssm_list_active_alarms     = module.ssm.list_active_alarms_doc
  ssm_list_sns_subscriptions = module.ssm.list_sns_subscriptions_doc
  # EC2 — passes "ec2-documents-disabled" until flag is true
  ssm_describe_instances     = module.ssm.describe_instances_doc
  ssm_stop_instance          = module.ssm.stop_instance_doc
  ssm_restart_instance       = module.ssm.restart_instance_doc
}

module "cloudwatch" {
  source            = "../../modules/cloudwatch"
  lambda_function_name = module.lambda.function_name
}

module "eventbridge" {
  source              = "../../modules/eventbridge"
  sns_topic_arn       = module.cloudwatch.sns_topic_arn
  lambda_function_arn = module.lambda.function_arn
}

module "chatbot" {
  source            = "../../modules/chatbot"
  role_arn          = module.iam.chatbot_role_arn
  sns_topic_arn     = module.cloudwatch.sns_topic_arn
  slack_workspace_id = var.slack_workspace_id
  slack_channel_id   = var.slack_channel_id
}

module "dashboard" {
  source      = "../../modules/dashboard"
  environment = var.environment
}
