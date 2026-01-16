# Cloud SQL Disallow External Scripts Custom Constraint

This module creates a custom organization policy constraint that ensures the 'external scripts enabled' flag is set to 'off' for all Cloud SQL for SQL Server instances.

**Note:** This constraint only applies to Cloud SQL for SQL Server instances. It does not affect other database types like MySQL or PostgreSQL.

## Security Rationale

**Why this constraint matters:**
- **Reduces Attack Surface**: External scripts can execute arbitrary code on the database server
- **Prevents Code Execution**: Blocks attackers from running malicious scripts via SQL injection
- **Compliance**: Required for many security frameworks that mandate minimal database permissions
- **Least Privilege**: External scripts violate the principle of least privilege
- **Data Protection**: Prevents unauthorized access to server file system

Enabling external scripts on SQL Server allows execution of code outside the database engine, creating significant security risks.

## How It Works

This constraint uses a CEL expression to verify that SQL Server instances do not have external scripts enabled.

**Technical Details:**
- **Resource Type**: `sqladmin.googleapis.com/Instance`
- **Action Type**: `DENY` (blocks instances with external scripts enabled)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: Checks that SQL Server instances have `external_scripts_enabled` flag set to `off`
- **Scope**: Only applies to SQL Server instances (versions starting with `SQLSERVER_`)

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_sql_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_sql_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for disallowing external scripts |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a Cloud SQL for SQL Server instance with the 'external scripts enabled' flag set to 'on'. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create SQL Server instance with external scripts enabled
gcloud sql instances create test-sql-server-noncompliant \
  --database-version=SQLSERVER_2019_STANDARD \
  --region=us-central1 \
  --root-password=YOUR_SECURE_PASSWORD \
  --database-flags=external_scripts_enabled=on
```

**Expected error:**
```
ERROR: (gcloud.sql.instances.create) HTTPError 412: Constraint custom.sqlDisallowExternalScriptsXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create SQL Server instance with external scripts disabled (or flag omitted)
gcloud sql instances create test-sql-server-compliant \
  --database-version=SQLSERVER_2019_STANDARD \
  --region=us-central1 \
  --tier=db-custom-2-7680 \
  --root-password=YOUR_SECURE_PASSWORD \
  --database-flags=external_scripts_enabled=off
```

### Terraform-based Testing

For complete Terraform validation examples, see the test cases in:
```
../../tests/sql/disallow-external-scripts-constraint/
```

These tests include both compliant and non-compliant SQL Server instance configurations.

## Notes

- **SQL Server only**: This constraint only applies to SQL Server instances (versions starting with `SQLSERVER_`)
- **MySQL and PostgreSQL**: Not affected by this constraint
- **Default behavior**: By default, external scripts are disabled on new SQL Server instances
- **R and Python**: This flag controls the ability to run R and Python scripts within SQL Server
