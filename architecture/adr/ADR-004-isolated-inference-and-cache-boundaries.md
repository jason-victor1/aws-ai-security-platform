# ADR-004: Air-Gapped VPC Inference Fabric and Multi-Tenant Cache Isolation

## Status
Accepted

## Context
Serving foundation models and agent reasoning engines introduces hardware- and memory-level vulnerabilities:
1. **Unauthenticated Fabric Snooping:** Inference runtimes deployed with default internet gateways or public IP assignments can be coerced into exfiltrating weights, activation traces, or prompt memory over out-of-band egress channels.
2. **Multi-Tenant KV-Cache Bleed:** Modern high-throughput inference engines (e.g., vLLM, SGLang) leverage radix-tree prefix caching to share common prompt prefixes across requests. In shared multi-tenant environments, stateful cache reuse creates timing side channels and risks bleeding sensitive cross-tenant context if boundaries are not strictly isolated.

## Decision
We enforce network- and memory-level isolation for the model serving runtime:
1. **Zero-Egress Inference VPC:** The inference runtime runs within a dedicated VPC with no Internet Gateway (IGW) and no NAT Gateway. All communication to AWS services (e.g., S3 model registry) is routed privately via AWS VPC Gateway Endpoints.
2. **CIDR-Restricted Security Group Ingress:** Serving port 8000 is restricted strictly to internal private VPC CIDR blocks (`10.100.0.0/16`), preventing external ingress.
3. **Deterministic Cache Boundary Enforcement:** Multi-tenant deployments disable cross-tenant prefix caching (`--enable-prefix-caching=false`) or mandate separate inference worker pools partitioned by tenant classification.

## Consequences
### Positive
- Prevents out-of-band data exfiltration from compromised model runtimes.
- Eliminates cross-tenant prompt memory leakage and radix-cache timing attacks.

### Negative / Trade-offs
- Disabling shared prefix caching reduces token throughput by 15–30% on repetitive prompt prefixes.
- Model runtimes cannot reach external APIs without provisioning monitored PrivateLink interface endpoints.
