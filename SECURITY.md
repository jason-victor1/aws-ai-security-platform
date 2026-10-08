# Security Policy

## Reporting Security Vulnerabilities

We take the security of the **AWS AI Security Platform** seriously. If you discover a vulnerability in our deterministic policy gates, token normalizers, microVM execution boundaries, or identity broker, please disclose it responsibly.

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing the maintainer directly at:
**jason_victor@outlook.com**

Include the following details in your report:
- **Type of vulnerability** (e.g., split-token evasion, Rego grammar bypass, ambient IAM privilege escalation, vector namespace traversal).
- **Step-by-step reproduction instructions** or minimal proof-of-concept payload (e.g., sample ticket payload, malicious runbook vector, or malformed tool schema).
- **Potential impact** across the 6 architectural pillars.

---

## Response & Triage SLAs

* **Initial Triage:** Within 48 hours of receipt.
* **Assessment & Confirmation:** Within 5 business days.
* **Remediation & Patch Deployment:** Critical severity issues within 14 days; high severity within 30 days.

---

## Safe Harbor & Research Scope

We consider vulnerability research conducted under this policy to be authorized. We will not pursue legal action against security researchers who:
- Make a good-faith effort to avoid privacy violations, data destruction, and service interruption.
- Test only against local or sandboxed environments and do not attempt denial-of-wallet / resource exhaustion against shared infrastructure.
- Give maintainers reasonable time to remediate the vulnerability before public disclosure.

### Out of Scope
- Theoretical LLM behavioral anomalies or standard prompt persuasion that remain constrained inside the Firecracker sandbox and do not bypass deterministic policy gates.
- Volume-based Denial of Service (DoS) or brute-force attacks against perimeter endpoints.
- Vulnerabilities requiring compromised local developer hardware or root workstation access.
