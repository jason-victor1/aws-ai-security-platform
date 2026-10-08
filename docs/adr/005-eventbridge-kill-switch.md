# ADR-005: EventBridge Kill-Switch Containment vs. Reactive CloudWatch Metrics

## Status
Accepted

## Context
When an autonomous agent enters a runaway execution loop (AML.T0031) or generates anomalous API bursts, reactive CloudWatch Metric Alarms introduce a 1-to-5 minute aggregation delay. During this window, an unchecked agent could cause service degradation or financial exhaustion.

## Decision
Implement a sub-second, event-driven circuit breaker architecture:
1. The STS Broker and Ingress Gateway emit real-time telemetry events to a custom EventBridge event bus (`ai-sec-platform-security-bus`).
2. An event rule monitors for circuit breaker trip patterns (e.g., consecutive policy violations, rate threshold spikes).
3. Tripping the rule synchronously invokes a Containment Lambda that revokes active STS session credentials and updates the agent's isolation security group.

## Consequences
* **Positive:** Sub-second response time for threat containment; deterministic execution kill switch.
* **Negative:** Requires tuning trip thresholds to avoid premature containment on legitimate batch workloads.
