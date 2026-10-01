"""
Ephemeral STS Broker Lambda
Validates agent intent and brokers short-lived, task-attenuated AWS STS credentials.
"""

import json
import logging
import os
import re
from typing import Any, Dict, List

# Graceful import guard: Allows offline policy and intent testing without boto3 installed
try:
    import boto3
    from botocore.exceptions import ClientError
except ImportError:
    boto3 = None
    class ClientError(Exception):
        pass

logger = logging.getLogger()
logger.setLevel(logging.INFO)

BASE_AGENT_ROLE_ARN = os.environ.get("BASE_AGENT_ROLE_ARN", "")
ALLOWED_ACTIONS_MAP: Dict[str, List[str]] = {
    "aws:ecs:restart": [
        "ecs:DescribeServices",
        "ecs:UpdateService"
    ],
    "aws:ec2:reboot": [
        "ec2:DescribeInstances",
        "ec2:RebootInstances"
    ],
    "aws:s3:read-runbook": [
        "s3:GetObject"
    ]
}

ARN_VALIDATION_REGEX = re.compile(
    r"^arn:aws:[a-z0-9-]+:[a-z0-9-]*:[0-9]{12}:[a-zA-Z0-9-_./]+$"
)


class BrokerValidationError(Exception):
    """Raised when an incoming agent intent fails validation."""
    pass


def validate_intent(payload: Dict[str, Any]) -> None:
    """Enforces baseline validation before passing to STS."""
    required_fields = ["ticket_id", "target_action", "target_resource_arn"]
    for field in required_fields:
        if not payload.get(field):
            raise BrokerValidationError(f"Missing required parameter: '{field}'")

    action = payload["target_action"]
    if action not in ALLOWED_ACTIONS_MAP:
        raise BrokerValidationError(f"Target action '{action}' is unauthorized for agent role")

    resource_arn = payload["target_resource_arn"]
    if not ARN_VALIDATION_REGEX.match(resource_arn):
        raise BrokerValidationError(f"Invalid target ARN format: '{resource_arn}'")

    if "*" in resource_arn:
        raise BrokerValidationError("Wildcards not permitted in target resource ARN")


def build_session_policy(target_action: str, resource_arn: str) -> str:
    """Constructs an inline session policy strictly scoped to the task."""
    actions = ALLOWED_ACTIONS_MAP[target_action]
    policy = {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AgentScopedExecutionBoundary",
                "Effect": "Allow",
                "Action": actions,
                "Resource": resource_arn
            }
        ]
    }
    return json.dumps(policy)


def get_sts_client():
    if boto3 is None:
        raise RuntimeError("boto3 must be installed to assume AWS STS sessions")
    return boto3.client("sts")


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """AWS Lambda entrypoint."""
    try:
        body = json.loads(event["body"]) if "body" in event and isinstance(event["body"], str) else event
        logger.info("Processing credential request for ticket: %s", body.get("ticket_id"))

        validate_intent(body)

        session_policy_json = build_session_policy(
            target_action=body["target_action"],
            resource_arn=body["target_resource_arn"]
        )

        session_name = f"AgentTask-{body['ticket_id'][:16]}"
        sts_client = get_sts_client()

        response = sts_client.assume_role(
            RoleArn=BASE_AGENT_ROLE_ARN,
            RoleSessionName=session_name,
            DurationSeconds=900,
            Policy=session_policy_json
        )

        credentials = response["Credentials"]

        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": "APPROVED",
                "ticket_id": body["ticket_id"],
                "credentials": {
                    "access_key_id": credentials["AccessKeyId"],
                    "secret_access_key": credentials["SecretAccessKey"],
                    "session_token": credentials["SessionToken"],
                    "expiration": credentials["Expiration"].isoformat()
                },
                "scoped_policy": json.loads(session_policy_json)
            })
        }

    except BrokerValidationError as e:
        logger.warning("Validation rejected: %s", str(e))
        return {
            "statusCode": 403,
            "body": json.dumps({
                "status": "DENIED",
                "error": "PolicyViolation",
                "message": str(e)
            })
        }
    except ClientError as e:
        logger.error("AWS STS client error: %s", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({
                "status": "ERROR",
                "message": "Failed to broker STS session"
            })
        }
    except Exception as e:
        logger.error("Unexpected error: %s", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({
                "status": "ERROR",
                "message": "Internal broker error"
            })
        }
