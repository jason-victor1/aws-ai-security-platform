package main

import rego.v1

# Ensure tool dispatch contains required contract metadata
deny contains msg if {
    not input.ticket_id
    msg := "[SCHEMA] Missing required field: 'ticket_id'"
}

deny contains msg if {
    not input.target_action
    msg := "[SCHEMA] Missing required field: 'target_action'"
}

# Enforce allowed CLI tool namespaces for the SRE remediation agent
allowed_namespaces := {
    "aws:ec2:describe",
    "aws:ec2:reboot",
    "aws:ecs:update-service",
    "aws:ecs:describe-tasks",
    "aws:s3:get-object",
    "aws:cloudwatch:get-metric-data"
}

deny contains msg if {
    input.target_action
    not input.target_action in allowed_namespaces
    msg := sprintf("[DISPATCH] Target action '%v' is not in the SRE agent whitelist", [input.target_action])
}

# Block shell injection primitives inside parameters
dangerous_chars := [";", "&&", "||", "`", "$", "|", ">", "<", "\n"]

deny contains msg if {
    param_val := input.parameters[_]
    is_string(param_val)
    char := dangerous_chars[_]
    contains(param_val, char)
    msg := sprintf("[INJECTION] Dangerous shell character '%v' detected in parameter: '%v'", [char, param_val])
}

# Block path traversal attempts
deny contains msg if {
    param_val := input.parameters[_]
    is_string(param_val)
    contains(param_val, "..")
    msg := sprintf("[TRAVERSAL] Directory traversal sequence '..' detected in parameter: '%v'", [param_val])
}
