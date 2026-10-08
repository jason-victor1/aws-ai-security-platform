# ADR-002: Keyless OIDC vs. Static IAM Machine Users in CI/CD

## Status
Accepted

## Context
CI/CD workflows that attest software bill of materials (AIBOM) and sign model checkpoints require AWS IAM credentials. Storing static IAM access keys (`AKIA...`) in repository secrets introduces supply chain compromise risks, credential rotation overhead, and non-repudiation gaps.

## Decision
Adopt keyless authentication using OpenID Connect (OIDC) federation between GitHub Actions and AWS STS (`sts:AssumeRoleWithWebIdentity`):
1. Register GitHub's OIDC provider URL (`https://token.actions.githubusercontent.com`) with the AWS IAM identity provider.
2. Scope the IAM trust policy strictly to repository IDs and exact subject claims (`repo:jason-victor1@170278602/aws-ai-security-platform@1400746070:*`).
3. Issue short-lived, cryptographically signed JWTs per workflow execution with zero stored secrets.

## Consequences
* **Positive:** Eliminates static credentials; enforces tamper-proof identity binding between workflow commits and IAM sessions.
* **Negative:** Requires precise IAM condition matching and explicit claim auditing during pipeline configuration.
