# ADR-003: Cryptographic Model Weight Attestation & CycloneDX AIBOM

## Status
Accepted

## Context
Deploying open-weight foundational models and fine-tuned checkpoints introduces severe supply-chain risks:
1. Legacy serialization formats (PyTorch `.pt`/`.bin` or Python `.pickle`) execute arbitrary OS-level bytecode during deserialization via `__reduce__`.
2. Model checkpoints stored in unverified registries can be silently replaced with backdoored weights or poisoned LoRA adapters.

## Decision
We establish a zero-trust model supply-chain protocol:
1. **Mandatory Safe Serialization:** All models and adapters must use the `.safetensors` format. Any `.bin`, `.pt`, or `.pickle` weights are rejected by admission gates.
2. **CycloneDX AIBOM Generation:** Every build pipeline computes SHA-256 digests of model weights, datasets, and base dependencies, generating an AI Software Bill of Materials.
3. **KMS-Backed Cosign Signatures:** Checkpoint digests are cryptographically signed using an asymmetric AWS KMS key (`ECC_NIST_P256`). Runtimes verify signatures prior to mounting weights into memory.

## Consequences
### Positive
- Completely neutralizes arbitrary deserialization exploits.
- Provides cryptographic non-repudiation and provenance for all weights in the cluster.

### Negative / Trade-offs
- Older model architectures relying on custom pickled layers must be explicitly converted to `.safetensors`.
- Checkpoint signing adds an extra step to model training and fine-tuning CI/CD pipelines.
