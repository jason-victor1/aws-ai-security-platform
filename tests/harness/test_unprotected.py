import json
import sys

print("\n" + "="*60)
print(" MODE: UNPROTECTED (Standard Naive AI Deployment)")
print("="*60)

# 1. Ingress: Naive string-based passthrough
print("\n[Pillar 1: Ingress Gateway - Unprotected]")
with open("tests/exploits/payload_token_smuggle.json") as f:
    payload = json.load(f)
print("  Payload received:", payload["description"][:50], "...")
print("  Naive check: Looking for 'ignore previous instructions'...")
print("  EXPLOIT RESULT: ⚠️ VULNERABLE (Zero-width characters and ChatML delimiters passed directly to model)")

# 2. RAG: Unfiltered vector retrieval
print("\n[Pillar 2: RAG Pipeline - Unprotected]")
with open("tests/exploits/payload_rag_poison.json") as f:
    rag_payload = json.load(f)
print(f"  Retrieving {len(rag_payload['retrieved_chunks'])} chunks without tenant boundary checks...")
for chunk in rag_payload["retrieved_chunks"]:
    print(f"    - Ingested chunk [{chunk['chunk_id']}] from tenant [{chunk['metadata']['tenant_id']}]")
print("  EXPLOIT RESULT: ⚠️ VULNERABLE (Cross-tenant leak and indirect prompt injection loaded into memory)")

# 3. Model Supply Chain: Blind model loading
print("\n[Pillar 3: Model Supply Chain - Unprotected]")
print("  Loading weights from remote storage without AIBOM verification...")
print("  Accepting unverified 'untrusted-pickle-weights' (.pickle format)...")
print("  EXPLOIT RESULT: ⚠️ VULNERABLE (Arbitrary code execution via unsafe deserialization)")

# 4. Inference Fabric: Public VPC with default internet routing
print("\n[Pillar 4: Serving Fabric - Unprotected]")
print("  Inference cluster deployed with public IP assignments and open 0.0.0.0/0 egress...")
print("  EXPLOIT RESULT: ⚠️ VULNERABLE (Unauthenticated RDMA fabric snooping and exfiltration feasible)")

# 5. Non-Human Identity: Static wildcard credentials
print("\n[Pillar 5: Identity Governance - Unprotected]")
with open("tests/exploits/payload_iam_escalate.json") as f:
    iam_payload = json.load(f)
print("  Agent issued permanent IAM Access Key with AdministratorAccess...")
print(f"  Agent attempting action: {iam_payload['Statement'][0]['Action']} on '*'")
print("  EXPLOIT RESULT: ⚠️ VULNERABLE (Privilege escalation succeeded; full AWS account takeover)")

# 6. Sandboxing: Direct shell execution
print("\n[Pillar 6: Execution Sandboxing - Unprotected]")
with open("tests/exploits/payload_tool_injection.json") as f:
    tool_payload = json.load(f)
cmd = f"aws iam delete-role --role-name {tool_payload['parameters']['role_name']}"
print(f"  Executing raw command string via os.system: '{cmd}'")
print("  EXPLOIT RESULT: ⚠️ VULNERABLE (Command injection chained arbitrary shell commands)")
