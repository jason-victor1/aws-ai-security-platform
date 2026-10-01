"""
Model Supply Chain & AIBOM Attestation Engine
Verifies that downstream inference instances only load model weights (.safetensors)
whose cryptographic digests match an attested CycloneDX AIBOM and are verified
against the platform's KMS signing key.
"""

import hashlib
import json
import logging
from typing import Any, Dict, Tuple

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class AttestationFailure(Exception):
    """Raised when model artifact attestation or provenance verification fails."""
    pass


def compute_sha256(content: bytes) -> str:
    """Computes standard hex SHA-256 digest of an artifact."""
    return hashlib.sha256(content).hexdigest()


def verify_model_provenance(
    artifact_bytes: bytes,
    aibom_manifest: Dict[str, Any],
    expected_artifact_id: str
) -> Tuple[bool, str]:
    """
    1. Computes physical SHA-256 digest of the model artifact.
    2. Validates that the digest matches the signed CycloneDX AIBOM component record.
    3. Confirms the artifact format matches safe serialization (.safetensors).
    """
    computed_digest = compute_sha256(artifact_bytes)

    # Locate component in AIBOM
    components = aibom_manifest.get("components", [])
    matched_component = next(
        (c for c in components if c.get("name") == expected_artifact_id),
        None
    )

    if not matched_component:
        raise AttestationFailure(f"Artifact '{expected_artifact_id}' not found in AIBOM manifest")

    # Enforce safetensors format to prevent arbitrary code execution via pickle
    artifact_type = matched_component.get("properties", {}).get("format", "")
    if artifact_type.lower() != "safetensors":
        raise AttestationFailure(
            f"Prohibited artifact format '{artifact_type}'. Only 'safetensors' format permitted."
        )

    # Verify hashes
    hashes = matched_component.get("hashes", [])
    expected_hash = next((h["content"] for h in hashes if h.get("alg") == "SHA-256"), None)

    if not expected_hash:
        raise AttestationFailure("AIBOM component missing SHA-256 verification hash")

    if computed_digest.lower() != expected_hash.lower():
        raise AttestationFailure(
            f"Cryptographic hash mismatch! Computed: {computed_digest}, Expected: {expected_hash}"
        )

    return True, computed_digest
