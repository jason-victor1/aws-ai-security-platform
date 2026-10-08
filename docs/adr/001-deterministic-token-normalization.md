# ADR-001: Deterministic Token Normalization over LLM-Based Self-Guardrails

## Status
Accepted

## Context
Deploying autonomous SRE agents exposes the system to prompt injection (AML.T0051) and token evasion techniques (e.g., zero-width spaces, homoglyphs, delimiter collisions). Relying on secondary LLM evaluation models (such as Llama Guard or NeMo Guardrails) introduces non-deterministic latency (200ms–1.5s per hop), variable inference cost, and susceptibility to sophisticated jailbreak phrasing that bypasses stochastic evaluators.

## Decision
Enforce strict, deterministic token normalization and payload validation at the L7 perimeter (Ingress Gateway) prior to LLM deserialization:
1. Normalize Unicode inputs using Canonical Decomposition followed by Canonical Composition (NFC).
2. Strip non-printable control characters, bidirectional override characters, and zero-width spaces.
3. Validate payloads against strict JSON Schemas and evaluate input boundaries using Open Policy Agent (Rego).

## Consequences
* **Positive:** Sub-millisecond deterministic filtering at L7; eliminates delimiter injection without inference overhead.
* **Negative:** Legitimate technical inputs containing non-standard Unicode or esoteric control sequences must be encoded or rejected.
