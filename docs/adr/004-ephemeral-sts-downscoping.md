# ADR-004: Ephemeral STS Downscoping vs. Permanent Workload Roles

## Status
Accepted

## Context
Autonomous incident-response agents require permissions to modify production infrastructure (e.g., restarting EC2 instances, rolling ECS tasks). Granting a permanent IAM execution role with ambient administrative authority creates severe privilege escalation risks (AML.T0025) if the agent is hijacked via prompt injection.

## Decision
Enforce dynamic, least-privilege credential brokering using AWS STS:
1. The agent runtime operates with zero ambient infrastructure modification privileges.
2. Remediations require presenting a validated incident ticket proposal to the STS Broker Lambda.
3. The broker issues a downscoped STS session token (`sts:AssumeRole`) restricted to the specific target resource ARN with a maximum session duration of 15 minutes.

## Consequences
* **Positive:** Limits compromised agent blast radius to a single approved resource with an aggressive TTL.
* **Negative:** Introduces a credential brokering hop before remediation operations can execute.
