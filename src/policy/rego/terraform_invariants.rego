package main

import rego.v1

# Deny open SSH/RDP security group ingress
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_security_group_rule"
    rule := resource.change.after
    rule.type == "ingress"
    rule.cidr_blocks[_] == "0.0.0.0/0"
    is_sensitive_port(rule.from_port, rule.to_port)
    msg := sprintf("[NETWORK] Ingress rule on security group opens sensitive port (%v-%v) to 0.0.0.0/0", [rule.from_port, rule.to_port])
}

# Deny unencrypted S3 buckets
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket_server_side_encryption_configuration"
    rules := resource.change.after.rule
    count(rules) == 0
    msg := sprintf("[STORAGE] S3 bucket '%v' lacks server-side encryption configuration", [resource.name])
}

# Helper: Flag ports 22 (SSH) and 3389 (RDP)
is_sensitive_port(from_port, to_port) if {
    from_port <= 22
    to_port >= 22
}

is_sensitive_port(from_port, to_port) if {
    from_port <= 3389
    to_port >= 3389
}
