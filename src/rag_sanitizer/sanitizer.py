"""
RAG Semantic Sanitizer & Context Boundary Filter
Enforces tenant namespace isolation and scrubs retrieved runbook context
for indirect prompt injection and imperative instruction overrides.
"""

import json
import logging
import re
from typing import Any, Dict, List, Tuple

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Imperative prompt injection patterns commonly embedded in poisoned runbooks
INDIRECT_INJECTION_PATTERNS = [
    re.compile(r"(?i)ignore\s+(all\s+)?(previous|prior)\s+(instructions|prompts|rules)"),
    re.compile(r"(?i)disregard\s+(all\s+)?(safety|system|operational)\s+guidelines"),
    re.compile(r"(?i)system\s*override\s*:"),
    re.compile(r"(?i)you\s+are\s+now\s+(an\s+unrestricted|in\s+developer\s+mode)"),
    re.compile(r"(?i)new\s+primary\s+directive\s*:"),
    re.compile(r"(?i)exfiltrate.*to\s+https?://"),
]


def sanitize_retrieved_chunk(content: str) -> Tuple[bool, str, List[str]]:
    """
    Inspects a single chunk of retrieved documentation.
    Returns: (is_safe, sanitized_content, matched_rules)
    """
    matches: List[str] = []

    for pattern in INDIRECT_INJECTION_PATTERNS:
        found = pattern.findall(content)
        if found:
            matches.append(pattern.pattern)

    if matches:
        return False, "[CONTENT DROPPED: INDIRECT PROMPT INJECTION DETECTED]", matches

    return True, content, []


def enforce_tenant_isolation(
    authenticated_tenant_id: str,
    chunks: List[Dict[str, Any]]
) -> List[Dict[str, Any]]:
    """
    Ensures vector metadata tenant_id strictly matches the authenticated session context.
    Eliminates cross-tenant vector contamination.
    """
    authorized_chunks = []
    for chunk in chunks:
        metadata = chunk.get("metadata", {})
        chunk_tenant = metadata.get("tenant_id")

        if chunk_tenant == authenticated_tenant_id:
            authorized_chunks.append(chunk)
        else:
            logger.warning(
                "Tenant boundary breach dropped: Authenticated=%s, ChunkOwner=%s",
                authenticated_tenant_id,
                chunk_tenant
            )

    return authorized_chunks


def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    AWS Lambda RAG Sanitizer entrypoint.
    Expects event:
    {
        "tenant_id": "tenant-corp-prod",
        "retrieved_chunks": [
            {
                "chunk_id": "chk-001",
                "metadata": {"tenant_id": "tenant-corp-prod", "source": "s3://runbooks/ecs.md"},
                "content": "Standard ECS restart: Verify cluster health..."
            }
        ]
    }
    """
    try:
        body = json.loads(event["body"]) if "body" in event and isinstance(event["body"], str) else event

        authenticated_tenant = body.get("tenant_id")
        raw_chunks = body.get("retrieved_chunks", [])

        if not authenticated_tenant or not isinstance(raw_chunks, list):
            return {
                "statusCode": 400,
                "body": json.dumps({"status": "REJECTED", "error": "Invalid tenant_id or retrieved_chunks format"})
            }

        # 1. Enforce strict tenant boundary
        tenant_filtered_chunks = enforce_tenant_isolation(authenticated_tenant, raw_chunks)

        # 2. Heuristic semantic sanitization across chunks
        sanitized_results = []
        dropped_count = 0

        for chunk in tenant_filtered_chunks:
            is_safe, sanitized_text, violations = sanitize_retrieved_chunk(chunk.get("content", ""))
            
            if not is_safe:
                dropped_count += 1
                sanitized_results.append({
                    "chunk_id": chunk.get("chunk_id"),
                    "status": "DROPPED",
                    "violations": violations
                })
            else:
                sanitized_results.append({
                    "chunk_id": chunk.get("chunk_id"),
                    "status": "CLEAN",
                    "content": sanitized_text,
                    "metadata": chunk.get("metadata")
                })

        return {
            "statusCode": 200,
            "body": json.dumps({
                "status": "PROCESSED",
                "tenant_id": authenticated_tenant,
                "total_chunks_evaluated": len(raw_chunks),
                "chunks_authorized": len(tenant_filtered_chunks),
                "poisoned_chunks_dropped": dropped_count,
                "clean_chunks": [c for c in sanitized_results if c["status"] == "CLEAN"]
            })
        }

    except Exception as e:
        logger.error("RAG Sanitizer error: %s", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "ERROR", "error": str(e)})
        }
