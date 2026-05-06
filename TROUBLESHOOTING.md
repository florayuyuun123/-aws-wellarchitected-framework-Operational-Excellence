# Troubleshooting Guide — ChatOps Bot on AWS

---

## How to Use This Guide

Each section maps to a module. Find the module where your issue occurs and follow the steps.
If an issue is not listed, check the [General Debugging](#general-debugging) section at the bottom.

---

## Table of Contents

1. [Terraform & Setup Issues](#1-terraform--setup-issues)
2. [IAM Issues](#2-iam-issues)
3. [SSM Document Issues](#3-ssm-document-issues)
4. [Lambda Issues](#4-lambda-issues)
5. [CloudWatch Alarm Issues](#5-cloudwatch-alarm-issues)
6. [EventBridge Issues](#6-eventbridge-issues)
7. [AWS Chatbot & Slack Issues](#7-aws-chatbot--slack-issues)
8. [Dashboard (S3 + CloudFront) Issues](#8-dashboard-s3--cloudfront-issues)
9. [General Debugging](#9-general-debugging)

---

## 1. Terraform & Setup Issues

### Error: `No valid credential sources found`
**Cause:** AWS CLI is not configured or credentials expired.
**Fix:**
```bash
aws configure
# Enter: Access Key, Secret Key, Region, Output format
```
Verify with:
```bash
aws sts get-caller-identity
```

---

### Error: `terraform: command not found`
**Cause:** Terraform is not installed or not in PATH.
**Fix:** Download from https://developer.hashicorp.com/terraform/downloads and add to PATH.

---

### Error: `Error acquiring the state lock`
**Cause:** A previous Terraform run crashed and left a lock.
**Fix:**
```bash
terraform force-unlock <LOCK_ID>
```
Lock ID is shown in the error message.

---

### Error: `Module not found` or `Module source not found`
**Cause:** Module path in `main.tf` is incorrect.
**Fix:** Verify the `source` path in `environments/dev/main.tf` matches the actual folder structure.

---

## 2. IAM Issues

### Error: `AccessDenied` when deploying resources
**Cause:** The IAM role or user running Terraform lacks permissions.
**Fix:**
- Confirm your AWS CLI identity: `aws sts get-caller-identity`
- Attach `AdministratorAccess` temporarily for initial setup, then scope down

---

### Error: `Lambda cannot assume role`
**Cause:** The trust policy on the IAM role does not include `lambda.amazonaws.com`.
**Fix:** Check `modules/iam/main.tf` — the assume role policy must include:
```json
{
  "Principal": { "Service": "lambda.amazonaws.com" },
  "Action": "sts:AssumeRole"
}
```

---

### Error: `Chatbot cannot assume role`
**Cause:** Trust policy missing `chatbot.amazonaws.com`.
**Fix:** Add `chatbot.amazonaws.com` to the trust policy in the chatbot IAM role.

---

## 3. SSM Document Issues

### Error: `Document already exists`
**Cause:** An SSM document with the same name was previously created manually.
**Fix:**
```bash
aws ssm delete-document --name "your-document-name"
terraform apply -target=module.ssm
```

---

### Error: `SSM execution failed — insufficient permissions`
**Cause:** The SSM role lacks required permissions for the command being run.
**Fix:** Review and update the IAM policy attached to `chatops-ssm-role` in `modules/iam/`.

---

### SSM document runs but does nothing
**Cause:** The document content has a syntax error or wrong schema version.
**Fix:**
```bash
aws ssm validate-document --content file://your-document.json
```

---

### EC2 commands not available in Slack
**Cause:** `enable_ec2_documents` is still set to `false` (default).
**Fix:** In `environments/dev/terraform.tfvars` set:
```hcl
enable_ec2_documents = true
```
Then run `terraform apply -target=module.ssm`.

---

### Only 4 documents showing in AWS Console instead of 7
**Cause:** Expected — EC2 documents are disabled by default.
**Fix:** See above. Only enable when you have EC2 instances to manage.

---

## 4. Lambda Issues

### Lambda function not triggering
**Cause:** EventBridge rule is not targeting the correct Lambda ARN, or Lambda has no resource-based policy allowing EventBridge.
**Fix:**
```bash
aws lambda get-policy --function-name your-function-name
```
Confirm EventBridge is listed as an allowed invoker.

---

### Error: `Runtime.ImportModuleError`
**Cause:** Lambda deployment package is missing dependencies.
**Fix:** Ensure all dependencies are packaged with the Lambda zip file before deploying.

---

### Lambda timeout
**Cause:** Default timeout (3s) is too short for SSM executions.
**Fix:** Increase timeout in `modules/lambda/main.tf`:
```hcl
timeout = 60
```

---

### Lambda logs not appearing in CloudWatch
**Cause:** Lambda execution role is missing `logs:CreateLogGroup` and `logs:PutLogEvents` permissions.
**Fix:** Add `AWSLambdaBasicExecutionRole` managed policy to the Lambda IAM role.

---

## 5. CloudWatch Alarm Issues

### Alarm stuck in `INSUFFICIENT_DATA`
**Cause:** The metric has no data points yet (e.g. no Lambda invocations).
**Fix:** Trigger the monitored resource to generate metrics, then wait 1–2 minutes.

---

### Alarm not transitioning to `ALARM` state during testing
**Cause:** Threshold is set too high, or the evaluation period is too long.
**Fix:** Temporarily lower the threshold in `modules/cloudwatch/main.tf` for testing, then restore.

---

### Alarm fires but no Slack notification received
**Cause:** The alarm is not connected to an SNS topic, or EventBridge is not routing correctly.
**Fix:** Check Step 6 (EventBridge) and Step 7 (Chatbot) troubleshooting sections.

---

## 6. EventBridge Issues

### EventBridge rule not triggering
**Cause:** Event pattern does not match the actual event structure.
**Fix:** Test the event pattern in AWS Console → EventBridge → Event buses → Send events.
Use a sample CloudWatch alarm event to verify the pattern matches.

---

### Error: `Target invocation failed`
**Cause:** EventBridge does not have permission to invoke the target (Lambda or SNS).
**Fix:** Add a resource-based policy on the target allowing `events.amazonaws.com` to invoke it.

---

## 7. AWS Chatbot & Slack Issues

### Slack OAuth not completing
**Cause:** You need Slack workspace admin rights to authorize AWS Chatbot.
**Fix:** Ask your Slack workspace admin to complete the OAuth step, or use a workspace where you are admin.

---

### AWS Chatbot configured but no messages in Slack
**Cause 1:** The SNS topic is not subscribed to the Chatbot channel configuration.
**Fix:** In AWS Console → Chatbot → your channel → confirm the SNS topic ARN is listed under Mapped SNS topics.

**Cause 2:** The Slack channel ID is wrong.
**Fix:** Right-click the Slack channel → "Copy link" — the channel ID is the last segment of the URL.

**Cause 3:** AWS Chatbot app was not invited to the Slack channel.
**Fix:** In Slack, open the `#aws-alerts` channel and type `/invite @AWS` then select AWS Chatbot.

**Cause 4:** Guardrail policy is blocking CloudWatch alarm events.
**Symptom:** Chatbot logs show `Event received is not supported` for every message.
**Fix:** Ensure guardrail policies in `modules/chatbot/variables.tf` are set to:
```hcl
default = [
  "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
  "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess",
  "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess",
  "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
  "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess"
]
```
Do NOT use `ReadOnlyAccess` — it silently blocks all CloudWatch alarm events.
After fixing, run:
```bash
terraform apply -target=module.chatbot
```

**Cause 5:** EventBridge input_transformer converting event to plain string.
**Symptom:** SNS receives the message but Chatbot drops it.
**Fix:** Remove `input_transformer` blocks from EventBridge targets in `modules/eventbridge/main.tf`.
Chatbot requires the raw JSON event, not a formatted string.

**How to check Chatbot logs for diagnosis:**
```bash
aws logs tail /aws/chatbot/chatops-slack-channel --since 1h
```
Look for either `Sending message to Slack` (success) or `Event received is not supported` (guardrail issue).

---

### Error: `Invalid Attribute Value Length` on slack_channel_id or slack_workspace_id
**Cause:** You ran `terraform apply` before filling in the Slack IDs — the `awscc` provider validates them immediately.
**Fix:** The Chatbot resource is guarded by a `count` — it skips deployment when IDs are empty. To activate:
1. Complete Slack OAuth in AWS Console → AWS Chatbot
2. Fill in both values in `environments/dev/terraform.tfvars`:
```hcl
slack_workspace_id = "TXXXXXXXXXX"
slack_channel_id   = "CXXXXXXXXXX"
```
3. Run `terraform apply -target=module.chatbot`
4. Confirm:
```bash
terraform output chatbot_slack_configured  # should return true
```

---

### Error: `Output refers to sensitive values`
**Cause:** An output references a variable marked `sensitive = true` without declaring the output as sensitive.
**Fix:** Add `sensitive = true` to the output, or wrap a non-sensitive boolean with `nonsensitive()`:
```hcl
# For ARNs and sensitive strings
output "chatbot_configuration_arn" {
  value     = module.chatbot.configuration_arn
  sensitive = true
}
# For booleans that reveal nothing sensitive
output "chatbot_slack_configured" {
  value = nonsensitive(module.chatbot.slack_configured)
}
```
To view sensitive outputs after apply:
```bash
terraform output -json chatbot_configuration_arn
```

---

### SNS topic policy blocking CloudWatch or CLI publishes
**Cause:** SNS topic policy only allows `events.amazonaws.com` — blocks CloudWatch alarm actions and CLI publishes.
**Fix:** Ensure the SNS topic policy in `modules/eventbridge/main.tf` includes all three principals:
```hcl
# EventBridge
{ Service = "events.amazonaws.com" }
# CloudWatch alarm actions
{ Service = "cloudwatch.amazonaws.com" }
# CLI and account-level publishes
{ AWS = "arn:aws:iam::ACCOUNT_ID:root" }
```
Then run `terraform apply -target=module.eventbridge`.

---

### Chatbot shows `FAILED` status
**Cause:** IAM role for Chatbot is missing required permissions.
**Fix:** Attach `AWSResourceExplorerReadOnlyAccess` and `CloudWatchReadOnlyAccess` to the Chatbot role.

---

### Commands sent in Slack return `Access Denied`
**Cause:** The guardrail policies do not cover the service being queried.
**Fix:** Add the required read-only policy to `guardrail_policy_arns` in `modules/chatbot/variables.tf`:
```hcl
default = [
  "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess",
  "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess",
  "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess",
  "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
  "arn:aws:iam::aws:policy/AmazonSNSReadOnlyAccess"
]
```
Then run `terraform apply -target=module.chatbot`.

---

### Amazon Q Developer returns `I can't answer that question`
**Cause:** Wrong command syntax — Amazon Q Developer does not use `run` or `aws` prefix.
**Fix:** Use this exact syntax:
```
@Amazon Q <service> <command> --region us-east-1
```
Examples:
```
# Wrong
@Amazon Q run aws lambda list-functions
@Amazon Q aws lambda list-functions

# Correct
@Amazon Q lambda list-functions --region us-east-1
@Amazon Q cloudwatch describe-alarms --region us-east-1
@Amazon Q ssm start-automation-execution --document-name chatops-list-lambdas --region us-east-1
```

---

### Amazon Q Developer responds with wrong command suggestion
**Cause:** Amazon Q misinterpreted your natural language input as a different AWS command.
**Fix:** Be explicit with the full service and command name:
```
@Amazon Q lambda list-functions --region us-east-1
```
Avoid short words like `enable`, `list`, `show` without a service name prefix.

---

## 8. Dashboard (S3 + CloudFront) Issues

### CloudFront URL returns 403 Forbidden
**Cause 1:** S3 bucket policy does not allow CloudFront OAC (Origin Access Control) to read objects.
**Fix:** Verify the S3 bucket policy in `modules/dashboard/main.tf` grants `s3:GetObject` to the CloudFront distribution.

**Cause 2:** `index.html` was not uploaded to S3.
**Fix:**
```bash
aws s3 ls s3://your-bucket-name/
```
If empty, re-run `terraform apply -target=module.dashboard`.

---

### CloudFront URL returns 404
**Cause:** CloudFront default root object is not set to `index.html`.
**Fix:** In `modules/dashboard/main.tf`, confirm:
```hcl
default_root_object = "index.html"
```

---

### CloudFront changes not reflecting (cached old content)
**Cause:** CloudFront is serving cached content.
**Fix:** Create an invalidation:
```bash
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

---

## 9. General Debugging

### Check Terraform state
```bash
terraform state list
terraform state show module.iam.aws_iam_role.lambda_role
```

### View CloudWatch Logs for Lambda
```bash
aws logs tail /aws/lambda/your-function-name --follow
```

### Test SNS → Slack pipeline manually
```bash
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:chatops-alerts \
  --message "Test alert from SNS"
```

### Validate all resources are deployed
```bash
terraform output
# Note: aws chatbot CLI commands do not work from terminal — use AWS Console instead
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `chatops`)]'
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:chatops-alerts
aws cloudwatch describe-alarms --alarm-name-prefix chatops
```

### Full reset (nuclear option)
```bash
terraform destroy
terraform apply
```

---

*Last updated: Full pipeline verified. Slack commands working. Amazon Q Developer syntax documented. All issues resolved.*
