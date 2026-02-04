# Enforce Logging for PostgreSQL Instances

This module creates custom organization policy constraints for Cloud SQL PostgreSQL instances to enforce comprehensive logging for auditing and security monitoring.

## Security Rationale

**Why this constraint matters:**
- **Auditing**: Records connections, disconnections, and structural changes (DDL), which are essential for incident response.
- **Data Leakage Prevention**: Disabling slow query logging prevents potentially sensitive data from being written to logs.
- **Visibility**: Ensures that database errors and warnings are captured with sufficient detail for security analysis.
- **SOC2 Compliance**: Meets rigorous logging requirements for organizational security audits.

## How It Works

The module creates multiple constraints using `DENY` logic to ensure specific PostgreSQL database flags are correctly configured.

**Technical Details:**
- **Resource Type**: `sqladmin.googleapis.com/Instance`
- **Action Type**: `DENY`
- **Method Types**: `CREATE`, `UPDATE`

### Required Flags
| Flag Name | Expected Value | Logic |
|-----------|----------------|-------|
| `log_connections` | `on` | Deny if not set to `on` |
| `log_disconnections` | `on` | Deny if not set to `on` |
| `log_error_verbosity` | `default` | Deny if explicitly changed from `default` |
| `log_min_duration_statement` | `-1` | Deny if explicitly changed from `-1` |
| `log_min_error_statement` | `error` | Deny if not set to `error` |
| `log_min_messages` | `warning` | Deny if not set to `warning` |
| `log_statement` | `ddl` | Deny if not set to `ddl` |

## Usage

This constraint is enabled via the `enable_sql_postgresql_constraints` variable in the SOC2 blueprint.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_names` | List of custom constraint names created |
| `org_policy_names` | List of organization policy names created |
