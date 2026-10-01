package main

import rego.v1

# Deny wildcard actions in Allow statements
deny contains msg if {
    statement := input.Statement[_]
    statement.Effect == "Allow"
    is_wildcard(statement.Action)
    msg := sprintf("[CRITICAL] Wildcard action '*' forbidden in statement: %v", [statement])
}

# Deny wildcard resources in Allow statements
deny contains msg if {
    statement := input.Statement[_]
    statement.Effect == "Allow"
    is_wildcard(statement.Resource)
    msg := sprintf("[CRITICAL] Wildcard resource '*' forbidden in statement: %v", [statement])
}

# Block dangerous privilege escalation actions
deny contains msg if {
    statement := input.Statement[_]
    statement.Effect == "Allow"
    action := get_actions(statement.Action)[_]
    action in dangerous_actions
    msg := sprintf("[SECURITY] Action '%v' violates agent privilege boundary", [action])
}

# Disallow PassRole unless scoped to a specific non-admin path
deny contains msg if {
    statement := input.Statement[_]
    statement.Effect == "Allow"
    action := get_actions(statement.Action)[_]
    action == "iam:PassRole"
    resource := get_resources(statement.Resource)[_]
    not startswith(resource, "arn:aws:iam::")
    msg := sprintf("[SECURITY] iam:PassRole must target an explicit ARN, got: '%v'", [resource])
}

# Helper: Detect wildcard strings or arrays
is_wildcard(val) if {
    val == "*"
}
is_wildcard(val) if {
    is_array(val)
    "*" in val
}

# Helper: Normalize actions to an array
get_actions(action) := [action] if {
    is_string(action)
}
get_actions(action) := action if {
    is_array(action)
}

# Helper: Normalize resources to an array
get_resources(res) := [res] if {
    is_string(res)
}
get_resources(res) := res if {
    is_array(res)
}

# Banned high-privilege IAM verbs
dangerous_actions := {
    "iam:AttachRolePolicy",
    "iam:AttachUserPolicy",
    "iam:AttachGroupPolicy",
    "iam:PutRolePolicy",
    "iam:PutUserPolicy",
    "iam:CreateAccessKey",
    "iam:CreateLoginProfile",
    "iam:UpdateLoginProfile",
    "iam:AddUserToGroup",
    "sts:AssumeRole",
    "organizations:LeaveOrganization"
}
