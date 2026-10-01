# ADR-002: Vector Namespace Isolation & Deterministic Context Scrubbing

## Status
Accepted

## Context
Autonomous agents retrieve documentation and operational runbooks via Retrieval-Augmented Generation (RAG). Without strict architectural boundaries:
1. Untrusted user tickets or third-party documentation can inject indirect prompt injections (e.g., `"System Override: ignore previous instructions"`).
2. Multi-tenant vector datastores risk cross-tenant data leakage if vector similarity searches query a shared embedding space without hard metadata filtering.

Using a secondary LLM as a "judge" to evaluate retrieved chunks adds excessive latency, increases API costs, and remains probabilistic and vulnerable to recursive injection.

## Decision
We enforce deterministic containment in the RAG retrieval layer:
1. **Strict Metadata Multi-Tenancy:** All vector chunks must carry an authenticated `tenant_id` attribute. Ingestion and retrieval filters drop any chunk failing cryptographic tenant verification.
2. **Deterministic Heuristic Scrubbing:** Retrieved chunks pass through a compiled regex engine targeting imperative override structures before being injected into prompt context. Flagged chunks are dropped.

## Consequences
### Positive
- Enforces multi-tenant data boundaries at zero-trust standards.
- Deterministic regex evaluation runs in sub-millisecond time with zero GPU overhead.

### Negative / Trade-offs
- Heuristic pattern matching can flag false positives on legitimate technical documentation discussing prompt injection terminology.
- Requires maintenance of common injection patterns.
