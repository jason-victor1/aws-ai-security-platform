# ADR-005: Task-Scoped Ephemeral STS Sessions Over Static Agent Credentials

## Status
Accepted

## Context
Autonomous agents executing remediation actions (e.g., restarting services, reading runbooks) frequently suffer from over-privileged identity design:
1. Assigning long-lived IAM access keys or broad role attachments (`AdministratorAccess`, `AmazonEC2FullAccess`) allows prompt-injected agents to execute Confused Deputy attacks across the entire AWS account.
2. Static credentials lack contextual linkage to specific operational tasks, making CloudTrail audit logs difficult to correlate with specific incident tickets.

## Decision
We enforce a zero-ambient-authority model for agent executions via an Ephemeral STS Credential Broker:
1. **Zero Ambient Cloud Permissions:** Agents and execution runners hold zero ambient AWS IAM permissions.
2. **Intent Verification:** Before executing any action, the agent submits an intent envelope (`ticket_id`, `target_action`, `target_resource_arn`) to the STS Broker Lambda.
3. **Dynamic Session Policy Attenuation:** The broker verifies the intent against an allowed actions map, rejects wildcard ARNs, and calls `sts:AssumeRole` with an inline, dynamically generated session policy that restricts the temporary session exclusively to the target resource ARN for 900 seconds.

## Consequences
### Positive
- Restricts the blast radius of a compromised agent to a single target resource ARN.
- Embeds the incident ticket ID directly into CloudTrail session identifiers (`AgentTask-INC-xxxxx`).
- Eliminates hardcoded long-lived credentials.

### Negative / Trade-offs
- Introduces an STS `AssumeRole` call prior to each atomic remediation task.
- Requires maintenance of the allowed actions mapping within the broker control plane.
