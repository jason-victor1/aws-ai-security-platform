# ADR-001: Token-Aware Ingress Normalization Over Traditional WAF Inspection

## Status
Accepted

## Context
Traditional Web Application Firewalls (AWS WAF, ModSecurity) evaluate payloads as raw byte or UTF-8 character streams against regex signatures. Modern LLM architectures tokenize input into sub-word tokens via Byte-Pair Encoding (BPE). Attackers exploit discrepancies between character inspection and token generation via:
1. **Zero-width characters & invisible codepoints** (`\u200B`, `\uFEFF`) that disrupt regex pattern matching while modern tokenizer implementations strip or reassemble them into malicious control tokens.
2. **Unicode confusable attacks** where non-ASCII characters map to identical visual glyphs but bypass strict ASCII WAF rules.
3. **Delimiter smuggling** injecting model-specific framing tokens (e.g., ChatML `<|im_start|>`, Llama `[INST]`) directly into user fields.

## Decision
We enforce a pre-inference ingress gateway Lambda that applies:
1. Deterministic detection of zero-width split-token characters prior to canonicalization.
2. Unicode NFKC (Compatibility Decomposition followed by Canonical Composition) normalization.
3. Direct validation against a prohibited set of downstream model control delimiters.

## Consequences
### Positive
- Closes the semantic seam between WAF byte streams and model tokenizers.
- Rejects adversarial split-token payloads at the perimeter before GPU memory or LLM tokens are consumed.

### Negative / Trade-offs
- Adds single-digit millisecond latency (typically 3–15ms) to request ingress.
- Must be updated if the downstream foundation model adopts non-standard delimiter syntax.
