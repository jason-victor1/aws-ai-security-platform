# ADR-003: Asymmetric KMS Cosign Signatures for Model Weight Provenance

## Status
Accepted

## Context
Autonomous agents rely on model weights stored in cloud storage (S3). Unauthorized modification, adversarial weight poisoning, or pipeline supply chain tampering (AML.T0010) could result in untrusted model execution.

## Decision
Implement cryptographic artifact signing and verification using Sigstore Cosign integrated with an asymmetric AWS KMS customer managed key:
1. Provision a dedicated asymmetric KMS key (`ECC_NIST_P256` under `SIGN_VERIFY` usage).
2. Compute deterministic SHA-256 digests of safetensors weights during CI builds and sign the digest directly via `cosign sign-blob --key awskms:///<ARN>`.
3. Require cryptographic verification (`cosign verify-blob`) prior to loading weights into inference runtime memory.

## Consequences
* **Positive:** Cryptographically guarantees model integrity and provenance; prevents execution of untrusted weights.
* **Negative:** Requires KMS API access permissions during inference runtime initialization.
