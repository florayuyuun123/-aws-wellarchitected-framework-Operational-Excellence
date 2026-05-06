import json
import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ssm = boto3.client("ssm")

# ─── Serverless commands — always available ───
COMMAND_MAP = {
    "list-lambdas":          os.environ["SSM_LIST_LAMBDAS"],
    "check-lambda":          os.environ["SSM_CHECK_LAMBDA_HEALTH"],
    "list-alarms":           os.environ["SSM_LIST_ACTIVE_ALARMS"],
    "list-subscriptions":    os.environ["SSM_LIST_SNS_SUBSCRIPTIONS"],
}

# ─── EC2 commands — only added when enabled ───
if os.environ.get("SSM_DESCRIBE_INSTANCES", "ec2-documents-disabled") != "ec2-documents-disabled":
    COMMAND_MAP["describe-instances"] = os.environ["SSM_DESCRIBE_INSTANCES"]
    COMMAND_MAP["stop-instance"]      = os.environ["SSM_STOP_INSTANCE"]
    COMMAND_MAP["restart-instance"]   = os.environ["SSM_RESTART_INSTANCE"]


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    body    = parse_body(event)
    command = body.get("command", "").strip().lower()
    params  = body.get("parameters", {})

    if command not in COMMAND_MAP:
        return response(400, {
            "message": f"Unknown command '{command}'.",
            "available": list(COMMAND_MAP.keys())
        })

    doc_name = COMMAND_MAP[command]

    try:
        result = ssm.start_automation_execution(
            DocumentName=doc_name,
            Parameters={k: [v] for k, v in params.items()} if params else {}
        )
        execution_id = result["AutomationExecutionId"]
        logger.info("SSM execution started: %s", execution_id)

        return response(200, {
            "message": f"Command '{command}' started successfully.",
            "executionId": execution_id,
            "document": doc_name
        })

    except ssm.exceptions.InvalidParameters as e:
        logger.error("Invalid parameters: %s", str(e))
        return response(400, {"message": f"Invalid parameters: {str(e)}"})

    except Exception as e:
        logger.error("Execution failed: %s", str(e))
        return response(500, {"message": f"Execution failed: {str(e)}"})


def parse_body(event):
    if "body" in event:
        try:
            return json.loads(event["body"]) if isinstance(event["body"], str) else event["body"]
        except (json.JSONDecodeError, TypeError):
            return {}
    return event


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body)
    }
