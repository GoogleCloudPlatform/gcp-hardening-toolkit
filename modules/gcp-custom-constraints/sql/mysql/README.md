# Enforce skip_show_database for MySQL Instances

This module creates a custom organization policy constraint that ensures Cloud SQL MySQL instances have the 'skip_show_database' flag set to 'on'.

## Security Rationale

**Why this constraint matters:**
- **Information Disclosure**: Prevents users from seeing database names they do not have access to.
- **Attack Surface Reduction**: Hiding existing database names makes it harder for malicious users to target specific databases for attacks.
- **Compliance**: Aligns with security best practices for database hardening.

## How It Works

The constraint uses `DENY` logic to block MySQL instances that do not have the `skip_show_database` flag explicitly enabled.

**Technical Details:**
- **Resource Type**: `sqladmin.googleapis.com/Instance`
- **Action Type**: `DENY`
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.databaseVersion.startsWith('MYSQL') && !resource.settings.databaseFlags.exists(f, f.name == 'skip_show_database' && f.value == 'on')`

## Usage

This constraint is enabled via the `enable_sql_mysql_constraints` variable in the SOC2 blueprint.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint |
| `org_policy_name` | The name of the organization policy |
