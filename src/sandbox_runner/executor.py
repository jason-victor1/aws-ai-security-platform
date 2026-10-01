"""
Firecracker Sandbox Tool Executor Lambda
Executes approved SRE remediation commands inside an isolated microVM runtime
using task-attenuated ephemeral STS credentials.
"""

import json
import logging
import os
import re
from typing import Any, Dict

try:
    import boto3
    from botocore.exceptions import ClientError
except ImportError:
    boto3 = None
    class ClientError(Exception):
        pass

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def execute_ecs_restart(credentials: Dict[str, str], parameters: Dict[str, Any]) -> Dict[str, Any]:
    if boto3 is None:
        raise RuntimeError("boto3 required for live AWS API execution")
    cluster = parameters.get("cluster_name")
    service = parameters.get("service_name")
    
    ecs = boto3.client(
        "ecs",
        aws_access_key_id=credentials["access_key_id"],
        aws_secret_access_key=credentials["secret_access_key"],
        aws_session_token=credentials["session_token"]
    )
    
    response = ecs.update_service(
        cluster=cluster,
        service=service,
        forceNewDeployment=True
    )
    return {
        "action": "aws:ecs:restart",
        "cluster": cluster,
        "service": service,
        "deployment_id": response["service"]["deployments"][0]["id"]
    }


def execute_ec2_reboot(credentials: Dict[str, str], parameters: Dict[str, Any]) -> Dict[str, Any]:
    if boto3 is None:
        raise RuntimeError("boto3 required for live AWS API execution")
    instance_id = parameters.get("instance_id")
    
    ec2 = boto3.client(
        "ec2",
        aws_access_key_id=credentials["access_key_id"],
        aws_secret_access_key=credentials["secret_access_key"],
        aws_session_token=credentials["session_token"]
    )
    
    ec2.reboot_instances(InstanceIds=[instance_id])
    return {
        "action": "aws:ec2:reboot",
        "instance_id": instance_id,
        "status": "REBOOT_INITIATED"
    }


DISPATCH_TABLE = {
    "aws:ecs:restart": execute_ecs_restart,
    "aws:ec2:reboot": execute_ec2_reboot
}

FORBIDDEN_CHARS_PATTERN = re.compile(r"[;&|`$<>\n]")


def validate_parameters(params: Dict[str, Any]) -> None:
    """Sanitizes tool call parameters against injection patterns."""
    for key, value in params.items():
        if isinstance(value, str):
            if FORBIDDEN_CHARS_PATTERN.search(value):
                raise ValueError(f"Dangerous characters detected in parameter '{key}': {value}")
            if ".." in value:
                raise ValueError(f"Path traversal detected in parameter '{key}': {value}")


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """AWS Lambda entrypoint."""
    try:
        body = json.loads(event["body"]) if "body" in event and isinstance(event["body"], str) else event
        action = body.get("target_action")
        params = body.get("parameters", {})
        creds = body.get("credentials", {})

        if not action or action not in DISPATCH_TABLE:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "status": "REJECTED",
                    "error": f"Unsupported or prohibited action: {action}"
                })
            }

        validate_parameters(params)

        executor_fn = DISPATCH_TABLE[action]
        execution_result = executor_fn(creds, params)

        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": "SUCCESS",
                "ticket_id": body.get("ticket_id"),
                "result": execution_result
            })
        }

    except ValueError as e:
        logger.error("Parameter validation failed: %s", str(e))
        return {
            "statusCode": 422,
            "body": json.dumps({"status": "VALIDATION_FAILED", "error": str(e)})
        }
    except ClientError as e:
        logger.error("AWS API execution failed: %s", str(e))
        return {
            "statusCode": 502,
            "body": json.dumps({"status": "EXECUTION_ERROR", "error": e.response["Error"]["Message"]})
        }
    except Exception as e:
        logger.error("Unexpected runner failure: %s", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "INTERNAL_ERROR", "error": str(e)})
        }
