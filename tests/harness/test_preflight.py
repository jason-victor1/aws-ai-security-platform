import json
import sys
import types
from pathlib import Path
from unittest.mock import MagicMock

# 1. Project root dynamic path resolution
PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

# 2. Standard-library stub for boto3/botocore when running outside AWS Lambda
if "boto3" not in sys.modules:
    try:
        import boto3
    except ImportError:
        # Create botocore.exceptions.ClientError inheriting from BaseException
        botocore_module = types.ModuleType("botocore")
        botocore_exceptions = types.ModuleType("botocore.exceptions")
        
        class ClientError(Exception):
            def __init__(self, error_response=None, operation_name=""):
                self.response = error_response or {"Error": {"Message": "Mocked Error"}}
                super().__init__(str(self.response))

        botocore_exceptions.ClientError = ClientError
        botocore_module.exceptions = botocore_exceptions
        sys.modules["botocore"] = botocore_module
        sys.modules["botocore.exceptions"] = botocore_exceptions

        # Create boto3 mock
        boto3_mock = MagicMock()
        sys.modules["boto3"] = boto3_mock

# 3. Import platform handlers and policy functions
from src.gateway.handler import handler as gateway_handler
from src.rag_sanitizer.sanitizer import handler as rag_handler
from src.sts_broker.broker import validate_intent, BrokerValidationError
from src.sandbox_runner.executor import validate_parameters

# --- Test Pillar 1: Ingress Token Gateway ---
with open("tests/exploits/payload_token_smuggle.json") as f:
    res = gateway_handler(json.load(f), None)
assert res["statusCode"] == 400, f"Pillar 1 Failed: Expected 400, got {res['statusCode']}"
body = json.loads(res["body"])
assert body["status"] == "BLOCKED_INGRESS_POLICY"
print("  - Pillar 1 (Token Ingress Normalizer): ✅ BLOCKED (Split-tokens & control frames caught)")

# --- Test Pillar 2: RAG Context Sanitizer ---
with open("tests/exploits/payload_rag_poison.json") as f:
    res = rag_handler(json.load(f), None)
assert res["statusCode"] == 200, f"Pillar 2 Failed: Expected 200, got {res['statusCode']}"
body = json.loads(res["body"])
assert body["chunks_authorized"] == 2
assert body["poisoned_chunks_dropped"] == 1
assert len(body["clean_chunks"]) == 1
print("  - Pillar 2 (RAG Semantic Sanitizer):   ✅ ISOLATED (Poisoned runbook dropped, tenant bounds enforced)")

# --- Test Pillar 5: STS Broker Intent Validation ---
valid_intent = {
    "ticket_id": "INC-12345",
    "target_action": "aws:ecs:restart",
    "target_resource_arn": "arn:aws:ecs:us-east-1:123456789012:service/prod/web"
}
validate_intent(valid_intent)

try:
    invalid_intent = {
        "ticket_id": "INC-12345",
        "target_action": "aws:iam:delete-role",
        "target_resource_arn": "arn:aws:iam::123456789012:role/admin"
    }
    validate_intent(invalid_intent)
    raise AssertionError("Pillar 5 Failed: Invalid intent passed validation!")
except BrokerValidationError:
    print("  - Pillar 5 (STS Broker Validation):    ✅ ENFORCED (Unauthorized action rejected before STS call)")

# --- Test Pillar 6: Sandbox Parameter Sanitizer ---
valid_params = {"cluster_name": "prod-cluster", "service_name": "auth-svc"}
validate_parameters(valid_params)

try:
    malicious_params = {"service_name": "auth-svc; rm -rf /"}
    validate_parameters(malicious_params)
    raise AssertionError("Pillar 6 Failed: Shell injection passed parameter validation!")
except ValueError:
    print("  - Pillar 6 (Sandbox Parameter Check):  ✅ ENFORCED (Shell metacharacters caught by runner)")
