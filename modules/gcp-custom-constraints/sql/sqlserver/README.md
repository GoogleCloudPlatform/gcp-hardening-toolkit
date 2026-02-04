# Enforce Security Hardening for SQL Server Instances

This module creates custom organization policy constraints for Cloud SQL SQL Server instances to enforce security best practices and compliance guardrails.

## Security Rationale

**Why this constraint matters:**
- **Attack Surface Reduction**: Disabling remote scripts and legacy remote access prevents unauthorized code execution.
- **Information Disclosure**: Trace Flag 3625 masks sensitive error details from non-admin users.
- **Centralized Auth**: Disabling contained database authentication forcing all auth through the server instance.
- **Least Privilege**: Restricting user connections and options prevents misconfigurations that could lead to resource exhaustion or security gaps.

## How It Works

The module creates multiple constraints using `DENY` logic to ensure specific SQL Server instance settings are correctly hardened.

**Technical Details:**
- **Resource Type**: `sqladmin.googleapis.com/Instance`
- **Action Type**: `DENY`
- **Method Types**: `CREATE`, `UPDATE`

### Hardening Steps
| Feature | Target State | Security Benefit |
|---------|--------------|------------------|
| External Scripts | `off` | Prevents unsanctioned R/Python script execution |
| Trace Flag 3625 | `on` | Masks sensitive parameters in error messages |
| Contained DB Auth | `off` | Enforces centralized server-level authentication |
| Cross DB Chaining | `off` | Prevents lateral movement across databases |
| Remote Access | `off` | Disables legacy RPC capability |
| User Connections | `0` | Ensures default/compliant connection limits |
| User Options | `none` | Prevents non-standard session defaults |

## Usage

This constraint is enabled via the `enable_sql_sqlserver_constraints` variable in the SOC2 blueprint.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_names` | List of custom constraint names created |
| `org_policy_names` | List of organization policy names created |
