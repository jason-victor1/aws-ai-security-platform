# AWS AI Security Platform

[![Validate Rego Policies & Terraform](https://github.com/jason-victor1/aws-ai-security-platform/actions/workflows/policy-test.yml/badge.svg)](https://github.com/jason-victor1/aws-ai-security-platform/actions/workflows/policy-test.yml)
[![Model Supply Chain Attestation](https://github.com/jason-victor1/aws-ai-security-platform/actions/workflows/sign-artifacts.yml/badge.svg)](https://github.com/jason-victor1/aws-ai-security-platform/actions/workflows/sign-artifacts.yml)
[![Branch Protection](https://img.shields.io/badge/branch%20protection-main%20enforced-success?logo=github)](https://github.com/jason-victor1/aws-ai-security-platform/blob/main/SECURITY.md)
[![Security Policy](https://img.shields.io/badge/security-SECURITY.md-blue?logo=security)](./SECURITY.md)

> **Deterministic Control Plane for Autonomous AI Agents and LLM Workloads on AWS.**  
> Enforces zero-trust isolation, ephemeral IAM brokering, supply-chain weight attestation, and real-time execution circuit breakers to prevent model exploitation, prompt injection escapes, and ambient authority compromise.

---

## Stage 1: Hero Architecture & Execution Flow

```text
+---------------------------------------------------------------------------------------------------------+
|                                    AWS AI SECURITY PLATFORM RUNTIME                                     |
+---------------------------------------------------------------------------------------------------------+
|                                                                                                         |
|   Untrusted Ticket / Prompt                                                                             |
|            |                                                                                            |
|            v                                                                                            |
|   +-------------------+    Clean Context    +-------------------+    Signed Weights   +---------------+ |
|   |  01 Ingress Guard | ------------------> |  02 RAG Datastore | ------------------> | 03 Model Reg. | |
|   |  (Token Normal.)  |                     |  (KMS / S3 San.)  |                     | (Cosign / KMS)| |
|   +-------------------+                     +-------------------+                     +---------------+ |
|            |                                                                                  |         |
|            | Policy Breach                                                            Payload | Attested|
|            v                                                                                  v         |
|   [ 403 Forbidden ]                                                                   +---------------+ |
|                                                                                       | 04 Inference  | |
|                                                                                       | (Isolated VPC)| |
|                                                                                       +---------------+ |
|                                                                                               |         |
|                                                                                        Action | Proposal|
|                                                                                               v         |
|   +-------------------+     Scoped STS      +-------------------+    Constrained Ops  +---------------+ |
|   | 06 Circuit Breaker| <------------------ |   05 STS Broker   | <------------------ | Agent Engine  | |
|   | (Kill Switch/Bus) |                     | (Downscoped Sess) |                     |  (Execution)  | |
|   +-------------------+                     +-------------------+                     +---------------+ |
+---------------------------------------------------------------------------------------------------------+
```

### End-to-End Operational Flow
1. **L7 Ingress Sanitization:** API Gateway strips homoglyphs, invisible Unicode, and prompt boundary escapes before Lambda payload deserialization.
2. **Context Attestation:** RAG vector lookups are evaluated against KMS-encrypted S3 data stores; context poisoning attempts trigger immediate quarantine.
3. **Cryptographic Model Verification:** Model weights are verified against asymmetric AWS KMS signatures (`ECC_NIST_P256`) via Cosign prior to memory ingestion.
4. **Air-Gapped Inference:** LLM workloads run in an isolated VPC with zero public egress, communicating solely via private AWS VPC Endpoints.
5. **Least-Privilege STS Brokering:** Dynamic IAM session tokens downscope ambient privileges based on specific action ticket IDs with 15-minute expirations.
6. **Execution Containment & Kill Switch:** Out-of-bounds agent operations trip the EventBridge security bus, firing Lambda-based container isolation and session revocation.

---

## Stage 2: Threat Modeling & Adversarial Taxonomy

This architecture is modeled against the **MITRE ATLAS** (Adversarial Threat Landscape for Artificial-Intelligence Systems) framework and the **OWASP Top 10 for LLMs**:

| Threat ID | Threat Vector | Attack Scenario | Architectural Countermeasure | Deterministic Policy Gate |
| :--- | :--- | :--- | :--- | :--- |
| **AML.T0051** | Prompt Injection (Direct & Indirect) | Attacker injects delimiters inside user ticket payload to force unauthorized EC2 termination. | L7 Normalizer + Rego Grammar Enforcement | `rego/policies/ingress_validation.rego` |
| **AML.T0043** | Vector / Context Poisoning | Malicious runbook markdown injected into RAG embeddings overrides agent operational rules. | Client-side KMS Envelope Encryption & Clean-Room Context Parser | `rego/policies/rag_sanitization.rego` |
| **AML.T0010** | Supply Chain Model Tampering | Backdoored safetensors weights published to S3 model bucket. | Sigstore/Cosign verification with KMS asymmetric key pair prior to load | `.github/workflows/sign-artifacts.yml` |
| **AML.T0048** | Exfiltration via Ambient Authority | Compromised agent attempts network egress to external C2 server. | VPC Private Isolation + Strict NACLs + No Internet Gateway | `terraform/modules/04-inference-runtime` |
| **AML.T0025** | Privilege Escalation via IAM | Agent leverages broad role permissions to assume administrative control across AWS accounts. | Dynamic STS Downscoper generating session policies with `< 15 min` TTL | `terraform/modules/05-sts-broker` |
| **AML.T0031** | Runaway Execution Loop | Agent enters autonomous destructive loop or denial-of-wallet tool invocation. | EventBridge Circuit Breaker rule triggering instant IAM session revocation | `terraform/modules/06-sandbox-circuit` |

---

## Stage 3: Defensive Architecture Matrix

The platform is structured into six independent, decoupled security pillars:

| Pillar | Subsystem | Enforcement Type | Core AWS Resources | Cryptographic / Policy Controls |
| :--- | :--- | :--- | :--- | :--- |
| **01** | Ingress Gateway | Deterministic Filter | API Gateway v2, Lambda (Python 3.11) | Unicode NFC normalization, JSON Schema, Token budget limits |
| **02** | RAG Datastore | Storage Boundary | Amazon S3, AWS KMS, GuardDuty S3 | KMS CMK encryption, Object Lock, MIME quarantine |
| **03** | Model Registry | Supply Chain Attestation | Amazon S3, Asymmetric KMS (`ECC_NIST_P256`) | Cosign blob signing, CycloneDX AIBOM SHA-256 digest pinning |
| **04** | Inference Runtime | Network Isolation | VPC, Private Subnets, S3 Gateway Endpoint | Zero-egress Security Groups, AWS PrivateLink |
| **05** | STS Token Broker | Identity Boundary | AWS STS, Lambda, Dynamic IAM Session Policies | Ephemeral credentials, SID-pinned boundary policies |
| **06** | Sandbox Circuit | Kill Switch / Containment | EventBridge Event Bus, CloudWatch Alarms | Real-time agent quarantine, IAM policy revocation |

---

## Stage 4: Deterministic Verification

All security boundaries are validated deterministically via reproducible Red-vs-Blue test suites and Open Policy Agent (Conftest) Rego evaluation.

### Quick Start: Local Test Harness

```bash
# 1. Clone repository
git clone https://github.com/jason-victor1/aws-ai-security-platform.git
cd aws-ai-security-platform

# 2. Execute deterministic verification harness
./scripts/run-verification.sh
```

### Verification Suite Outputs

```text
[✓] Step 1: Evaluating Infrastructure-as-Code Policies (Conftest / Rego)...
    PASS - terraform/modules/01-ingress-gateway (14/14 checks passed)
    PASS - terraform/modules/04-inference-runtime (18/18 checks passed)
    PASS - terraform/modules/05-sts-broker (12/12 checks passed)

[✓] Step 2: Red Team Adversarial Simulation (Attack Payloads)...
    [ATTACK 01] Delimiter Split Injection:      BLOCKED (HTTP 403 Forbidden)
    [ATTACK 02] Malicious S3 Runbook Poisoning: BLOCKED (Digest Mismatch)
    [ATTACK 03] Unsigned Model Checkpoint:      BLOCKED (Cosign Verification Failed)
    [ATTACK 04] Egress Data Exfiltration:       BLOCKED (Network Unreachable)
    [ATTACK 05] Unauthorized IAM Escalation:    BLOCKED (AccessDeniedException)
    [ATTACK 06] Runaway Agent Execution Loop:   TERMINATED (Circuit Breaker Tripped)

[✓] ALL 6 DEFENSIVE GATES DETERMINISTICALLY ATTESTED.
```

---

## Stage 5: Architecture Decision Records (ADRs) & Governance

Architectural choices are documented via formal Architecture Decision Records:

* [ADR-001: Deterministic Token Normalization over LLM-based Self-Guardrails](./docs/adr/001-deterministic-token-normalization.md)
* [ADR-002: Keyless OIDC vs Static IAM Machine Users in CI/CD](./docs/adr/002-keyless-oidc-attestation.md)
* [ADR-003: Asymmetric KMS Cosign Signatures for Model Weight Provenance](./docs/adr/003-kms-cosign-weight-provenance.md)
* [ADR-004: Ephemeral STS Downscoping vs Permanent Workload Roles](./docs/adr/004-ephemeral-sts-downscoping.md)
* [ADR-005: EventBridge Kill-Switch Containment vs Reactive CloudWatch Metrics](./docs/adr/005-eventbridge-kill-switch.md)

### Repository Governance
* **Vulnerability Disclosure Policy:** Documented in [SECURITY.md](./SECURITY.md) with defined triage SLAs and safe harbor scope.
* **Branch Protection:** Strict enforcement on `main` requiring passing CI status checks (`Validate Rego Policies & Terraform`) before merging.
* **Non-Human Identity Security:** Zero static access keys. Workload execution and CI/CD pipelines authenticate exclusively via OpenID Connect (OIDC) and ephemeral STS sessions.
