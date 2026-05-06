# Operational Excellence Pillar — ChatOps Bot on AWS
## Real-Time AWS Operations from Slack

---

## Project Overview

This project implements the AWS Well-Architected Framework **Operational Excellence** pillar
by building a ChatOps bot that integrates AWS with Slack for real-time operations.

**No custom domain required.** All communication is outbound from AWS to Slack's API.

---

## Architecture

```
Slack Workspace
     ↑  ↓
AWS Chatbot  ←──────────────────────────────┐
     ↑                                       │
EventBridge  ←──  CloudWatch Alarms          │
     ↑                                       │
Lambda Functions  ←──  SSM Documents         │
     ↑                                       │
IAM Roles & Policies (secure access control) │
     ↑                                       │
Optional Dashboard: S3 + CloudFront ─────────┘
```

---

## Project Structure

```
operational-excellence/
├── modules/
│   ├── iam/              # Objective d - IAM roles & policies
│   ├── ssm/              # Objective b - SSM documents
│   ├── lambda/           # Objective b - Lambda functions
│   ├── cloudwatch/       # Objective c - CloudWatch alarms
│   ├── eventbridge/      # Objective c - EventBridge rules
│   ├── chatbot/          # Objective a - AWS Chatbot + Slack
│   └── dashboard/        # Objective e - S3 + CloudFront dashboard
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf          # variable declarations only — no sensitive values
│       ├── outputs.tf
│       ├── terraform.tfvars      # actual values — gitignored, never commit
│       └── terraform.tfvars.example  # safe template — committed to git
├── .gitignore
├── DOCUMENTATION.md      # This file
└── TROUBLESHOOTING.md    # Troubleshooting guide
```

---

## Cost Estimate (Monthly — Dev/Low Usage)

| Service | Usage Assumption | Estimated Cost |
|---|---|---|
| AWS Chatbot | Per notification sent to Slack | Free |
| Lambda | < 1M requests/month (free tier) | $0.00 |
| SSM Documents | Document storage + executions | ~$0.00 – $1.00 |
| CloudWatch Alarms | 10 alarms | ~$1.00 |
| CloudWatch Logs | 5 GB ingestion | ~$2.50 |
| EventBridge | < 1M events/month (free tier) | $0.00 |
| S3 (dashboard) | < 1 GB storage | ~$0.02 |
| CloudFront (dashboard) | < 1 TB transfer (free tier) | $0.00 |
| IAM | Always free | $0.00 |
| **Total Estimate** | | **~$3.50 – $5.00/month** |

> For production with higher alarm volumes and Lambda invocations, budget ~$15–$30/month.
> Use the [AWS Pricing Calculator](https://calculator.aws) for precise estimates based on your usage.

---

## Prerequisites

- [ ] AWS Account with admin access
- [ ] Terraform >= 1.5.0 installed
- [ ] AWS CLI configured (`aws configure`)
- [ ] Slack workspace where you have admin rights
- [ ] Slack channel created for AWS alerts (e.g. `#aws-alerts`) — create it in Slack first
- [ ] Slack Workspace ID — from AWS Console → Chatbot after OAuth
- [ ] Slack Channel ID — right-click channel → Copy link → last segment of URL

---

## Slack Command Syntax

Amazon Q Developer in Slack uses this pattern — no `aws` prefix, no `run` keyword:
```
@Amazon Q <service> <command> --region us-east-1
```

**Lambda:**
```
@Amazon Q lambda list-functions --region us-east-1
@Amazon Q lambda get-function --function-name chatops-chatops-handler --region us-east-1
```

**CloudWatch:**
```
@Amazon Q cloudwatch describe-alarms --region us-east-1
@Amazon Q cloudwatch describe-alarms --state-value ALARM --region us-east-1
```

**SSM Runbooks:**
```
@Amazon Q ssm start-automation-execution --document-name chatops-list-lambdas --region us-east-1
@Amazon Q ssm start-automation-execution --document-name chatops-list-active-alarms --region us-east-1
@Amazon Q ssm start-automation-execution --document-name chatops-check-lambda-health --parameters FunctionName=chatops-chatops-handler --region us-east-1
@Amazon Q ssm start-automation-execution --document-name chatops-list-sns-subscriptions --parameters TopicArn=arn:aws:sns:us-east-1:590184076844:chatops-alerts --region us-east-1
```

**SNS:**
```
@Amazon Q sns list-topics --region us-east-1
```

**EC2 (once enable_ec2_documents = true):**
```
@Amazon Q ssm start-automation-execution --document-name chatops-describe-instances --region us-east-1
@Amazon Q ssm start-automation-execution --document-name chatops-stop-instance --parameters InstanceId=i-1234567890abcdef0 --region us-east-1
@Amazon Q ssm start-automation-execution --document-name chatops-restart-instance --parameters InstanceId=i-1234567890abcdef0 --region us-east-1
```

> Commands run under `chatops-chatbot-role` and are limited by guardrail policies.
> Results are only visible to you in Slack unless Amazon Q posts them to the channel.

---

## Step-by-Step Deployment Guide

---

### Step 1 — IAM Roles & Policies (Module: `iam`)

**What it does:** Creates all IAM roles needed by Lambda, Chatbot, and SSM with least-privilege permissions.

**Files:** `modules/iam/`

**Deploy:**
```bash
cd environments/dev
terraform init
terraform apply -target=module.iam
```

**Verify:**
- Go to AWS Console → IAM → Roles
- Confirm roles: `chatops-lambda-role`, `chatops-chatbot-role`, `chatops-ssm-role` exist

---

### Step 2 — SSM Documents (Module: `ssm`)

**What it does:** Creates SSM Automation documents for runbook operations.
Serverless documents deploy by default — no EC2 instances required.
EC2 documents are included but disabled until you set `enable_ec2_documents = true`.

**Serverless documents (always deployed):**
| Document | Slack Command | Parameters |
|---|---|---|
| `chatops-list-lambdas` | `@Amazon Q lambda list-functions --region us-east-1` | none |
| `chatops-check-lambda-health` | `@Amazon Q ssm start-automation-execution --document-name chatops-check-lambda-health --parameters FunctionName=<value> --region us-east-1` | `FunctionName` |
| `chatops-list-active-alarms` | `@Amazon Q cloudwatch describe-alarms --state-value ALARM --region us-east-1` | none |
| `chatops-list-sns-subscriptions` | `@Amazon Q sns list-subscriptions-by-topic --topic-arn <value> --region us-east-1` | `TopicArn` |

**EC2 documents (disabled by default):**
| Document | Slack Command | Parameters |
|---|---|---|
| `chatops-describe-instances` | `@Amazon Q ssm start-automation-execution --document-name chatops-describe-instances --region us-east-1` | none |
| `chatops-stop-instance` | `@Amazon Q ssm start-automation-execution --document-name chatops-stop-instance --parameters InstanceId=<value> --region us-east-1` | `InstanceId` |
| `chatops-restart-instance` | `@Amazon Q ssm start-automation-execution --document-name chatops-restart-instance --parameters InstanceId=<value> --region us-east-1` | `InstanceId` |

**To enable EC2 documents** when you have instances, set this in `environments/dev/terraform.tfvars`:
```hcl
enable_ec2_documents = true
```
Then run `terraform apply` — EC2 documents deploy and Slack commands become available instantly.

**Files:** `modules/ssm/`

**Deploy:**
```bash
terraform apply -target=module.ssm
```

**Verify:**
- AWS Console → Systems Manager → Documents → Owned by me
- Confirm 4 serverless documents are listed
- EC2 documents only appear when `enable_ec2_documents = true`

---

### Step 3 — Lambda Functions (Module: `lambda`)

**What it does:** Deploys Lambda functions that execute SSM documents and respond to Slack commands.

**Files:** `modules/lambda/`

**Deploy:**
```bash
terraform apply -target=module.lambda
```

**Verify:**
- AWS Console → Lambda → Functions
- Test invoke the function manually with a test event

---

### Step 4 — CloudWatch Alarms (Module: `cloudwatch`)

**What it does:** Creates CloudWatch alarms for key metrics (CPU, errors, Lambda failures).

**Files:** `modules/cloudwatch/`

**Deploy:**
```bash
terraform apply -target=module.cloudwatch
```

**Verify:**
- AWS Console → CloudWatch → Alarms
- Confirm alarms are in OK or INSUFFICIENT_DATA state

---

### Step 5 — EventBridge Rules (Module: `eventbridge`)

**What it does:** Routes CloudWatch alarm state changes to AWS Chatbot for Slack delivery.

**Files:** `modules/eventbridge/`

**Deploy:**
```bash
terraform apply -target=module.eventbridge
```

**Verify:**
- AWS Console → EventBridge → Rules
- Confirm rules are enabled

---

### Step 6 — AWS Chatbot + Slack Integration (Module: `chatbot`)

**What it does:** Connects your Slack workspace to AWS Chatbot and links it to the SNS topic.

**Files:** `modules/chatbot/`

**Manual Step Required (one-time OAuth):**
1. Go to AWS Console → AWS Chatbot
2. Click "Configure new client" → Select Slack
3. Click "Allow" in the Slack OAuth screen
4. Copy the Workspace ID shown in the Chatbot console
5. Create a private channel in Slack e.g. `#aws-alerts` and invite the AWS Chatbot app to it
6. Get your Channel ID — right-click your `#aws-alerts` channel in Slack → Copy link → last segment
7. Add both values to `environments/dev/terraform.tfvars` — never share these in chat:
```hcl
slack_workspace_id = "TXXXXXXXXXX"
slack_channel_id   = "CXXXXXXXXXX"
```

> The Chatbot resource is guarded by a `count` — it skips deployment safely when IDs are empty
> and activates automatically once both values are filled in.

**Important — Guardrail Policies:**
The Chatbot channel uses these 5 guardrail policies. Do NOT replace them with `ReadOnlyAccess` —
it silently drops all CloudWatch alarm events with `Event received is not supported`:
- `CloudWatchReadOnlyAccess`
- `AWSResourceExplorerReadOnlyAccess`
- `AWSLambda_ReadOnlyAccess`
- `AmazonSSMReadOnlyAccess`
- `AmazonSNSReadOnlyAccess`

**Deploy:**
```bash
terraform apply -target=module.chatbot
```

**Verify:**
```bash
terraform output chatbot_slack_configured  # returns true when active
```
1. Go to AWS Console → AWS Chatbot → your workspace → `chatops-slack-channel`
2. Click "Send test message" — confirm it arrives in `#aws-alerts`
3. Trigger a real alarm test:
```bash
aws cloudwatch set-alarm-state \
  --alarm-name "chatops-lambda-errors" \
  --state-value ALARM \
  --state-reason "Pipeline test"
```
4. Confirm notification arrives in Slack then reset:
```bash
aws cloudwatch set-alarm-state \
  --alarm-name "chatops-lambda-errors" \
  --state-value OK \
  --state-reason "Reset after test"
```

---

### Step 7 — Optional Dashboard (Module: `dashboard`)

**What it does:** Deploys a static operations dashboard to S3, served via CloudFront.
Access URL will be: `https://<auto-generated>.cloudfront.net`

**Files:** `modules/dashboard/`

**Deploy:**
```bash
terraform apply -target=module.dashboard
```

**Verify:**
- AWS Console → CloudFront → Distributions
- Open the CloudFront URL in your browser

---

### Full Deployment (All Modules)

Once all modules are verified individually:
```bash
cd environments/dev
terraform apply
```

---

### Teardown

To destroy all resources:
```bash
terraform destroy
```

To destroy a single module:
```bash
terraform destroy -target=module.dashboard
```

---

## Sensitive Values & Secret Management

| File | Purpose | Committed to Git? |
|---|---|---|
| `variables.tf` | Variable type declarations only | Yes — safe |
| `terraform.tfvars` | All real values including Slack IDs | No — gitignored |
| `terraform.tfvars.example` | Placeholder template for onboarding | Yes — safe |

- Slack variables are marked `sensitive = true` in `variables.tf` — Terraform will never print them in logs
- Chatbot ARN output is marked `sensitive = true` — view it with `terraform output -json chatbot_configuration_arn`
- Never paste Slack IDs, AWS Account IDs, or ARNs into chat or email

---

## Outputs

After full deployment, `terraform output` will show:
- `cloudfront_dashboard_url` — open in browser
- `lambda_function_arn` — ARN of the ChatOps Lambda
- `sns_topic_arn` — ARN of the alerts SNS topic
- `chatbot_configuration_arn` — sensitive, use `terraform output -json`
- `chatbot_slack_configured` — `true` when Slack is connected

---

## Known Behaviours

These are expected behaviours you may encounter — they are not errors:

| Behaviour | What it means |
|---|---|
| `I tried to graph this data but something went wrong` | Amazon Q attempted to render a visual graph but the data format is not supported. The command still executed successfully — ignore this message |
| `Only visible to you` | Command results are private to you in Slack. This is correct security behaviour |
| `This is an abbreviated result` | AWS returned more data than Slack can display. Use the AWS Console or CLI for full output |
| `Would you like me to add optional parameters?` | Amazon Q is offering to help refine the command. You can ignore or respond with additional parameters |
| Alarm notification shows `I tried to graph` | Chatbot fetched the CloudWatch metric graph but could not render it in Slack. The alarm notification itself is still delivered correctly |
| `set-alarm-state` via CLI does not trigger EventBridge | Expected — `set-alarm-state` only changes the visual state. EventBridge only fires on real metric-driven state changes |

---

## Enabling EC2 Support Later

When you have EC2 instances and want to manage them from Slack:

1. Open `environments/dev/terraform.tfvars`
2. Change:
```hcl
enable_ec2_documents = true
```
3. Run:
```bash
cd environments/dev
terraform apply -target=module.ssm
```
4. No Lambda or other module changes needed — EC2 commands are automatically available in Slack immediately after apply.

---

*Last updated: Full pipeline verified. Slack commands working via Amazon Q Developer. Correct syntax: `@Amazon Q <service> <command> --region us-east-1`.*
