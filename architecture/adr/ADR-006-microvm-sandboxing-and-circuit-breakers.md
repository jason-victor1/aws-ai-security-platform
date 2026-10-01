# ADR-006: Firecracker MicroVM Sandboxing and Sub-Second Policy Circuit Breakers

## Status
Accepted

## Context
When autonomous agents generate CLI commands, API calls, or Terraform patches, standard container runtimes present two severe failure modes:
1. **Container Escape & Shared Kernel Exploits:** Standard Docker/container runtimes share the host Linux kernel, leaving the underlying node vulnerable to kernel privilege escalation and local lateral movement.
2. **Runaway Execution Loops (Denial of Wallet):** Probabilistic agent reasoning loops can enter recursive error cycles, issuing thousands of cloud API calls or provisioning expensive GPU instances before human intervention occurs.

## Decision
We enforce two-tier execution containment:
1. **Hardware-Virtualized MicroVM Isolation:** All agent tool executions run inside AWS Lambda functions natively isolated via Firecracker microVMs with read-only root filesystems and isolated virtual CPU/memory spaces.
2. **Pre-Execution Policy-as-Code Gates:** Agent-generated actions and Terraform plans pass through Conftest / Rego v1 policy checks before execution, deterministically rejecting wildcard IAM statements and shell injection operators.
3. **EventBridge Circuit Breaker:** Runaway execution spikes or critical policy violations emit events to a dedicated EventBridge security bus, triggering an automated kill-switch that revokes active STS credentials and terminates running tasks.

## Consequences
### Positive
- Provides hardware-level virtualization boundaries around untrusted agent execution.
- Intercepts malicious infrastructure modifications deterministically in sub-second time.
- Prevents financial exhaustion from runaway autonomous agent loops.

### Negative / Trade-offs
- Firecracker environments cannot run persistent Docker daemons natively inside the execution thread.
- Cold-start invocation latency on unprimed Lambda sandboxes (typically 150–400ms).
