# Contributing to AWS AI Security Platform

Thank you for your interest in contributing to the AWS AI Security Platform reference implementation.

## Core Engineering Invariants

All pull requests must strictly adhere to the project architectural principles:
1. **Deterministic Over Probabilistic:** Security boundaries must execute via deterministic Policy-as-Code (Rego), cryptographic verification (KMS/Cosign), or hardware-level isolation (Firecracker microVMs). Never rely on an LLM to evaluate the safety of another LLM without a hard outer deterministic sandbox.
2. **Zero Ambient Cloud Permissions:** Agent runners must hold zero ambient AWS IAM permissions. All credentials must be broker-attenuated via Pillar 5.
3. **No Breaking Invariants:** Existing Conftest Rego policies in `src/policy/rego/` must remain in strict compliance with Rego v1 grammar.

## Local Pre-Flight Verification

Before opening a pull request, run the complete verification suite locally:

```bash
# Run local pre-flight checks and unit tests
python3 tests/harness/test_preflight.py
python3 tests/harness/test_phase3.py

# Run the full Red vs. Blue verification suite
./tests/run-verification.sh --all

# Validate Terraform configurations
cd terraform/environments/dev
terraform validate
```

## Policy Changes

When introducing or modifying Rego policies in `src/policy/rego/`:
- Add matching positive and negative test cases to `tests/exploits/`.
- Ensure all rules return human-readable failure descriptions prefixed with the policy domain (e.g., `[CRITICAL]`, `[SECURITY]`, `[DISPATCH]`).
