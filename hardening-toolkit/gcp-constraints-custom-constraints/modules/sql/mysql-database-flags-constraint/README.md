# Enforce MySQL Database Flags Constraint

This module creates a custom organization policy constraint that ensures all Cloud SQL for MySQL instances have critical security flags properly configured.

## Security Rationale

**Why this constraint matters:**

This constraint enforces two critical MySQL security flags:

### `skip_show_database = on`
- **Prevents Database Enumeration**: Users can only see databases they have privileges for
- **Reduces Attack Surface**: Attackers cannot discover database names to target
- **Compliance**: Required for least-privilege access models

### `local_infile = off`
- **Prevents Data Exfiltration**: Disables loading local files into database tables
- **Blocks SQL Injection Attacks**: Prevents attackers from reading server files via SQL injection
- **Security Best Practice**: Recommended by CIS MySQL Benchmark

Without these flags, attackers could enumerate databases and potentially exfiltrate sensitive data.

## How It Works

This constraint uses a CEL expression to verify both flags are set correctly on MySQL instances.

**Technical Details:**
- **Resource Type**: `sqladmin.googleapis.com/Instance`
- **Action Type**: `DENY` (blocks non-compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: Checks that MySQL instances have both flags set correctly

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_sql_mysql_database_flags_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_sql_mysql_database_flags_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for MySQL database flags |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a MySQL instance without the required flags. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create MySQL instance without required flags
gcloud sql instances create test-mysql-noncompliant \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=us-central1
```

**Expected error:**
```
ERROR: (gcloud.sql.instances.create) HTTPError 412: Constraint custom.sqlMysqlDatabaseFlagsXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create MySQL instance with required flags
gcloud sql instances create test-mysql-compliant \
  --database-version=MYSQL_8_0 \
  --tier=db-f1-micro \
  --region=us-central1 \
  --database-flags=skip_show_database=on,local_infile=off
```

### Terraform-based Testing

For complete Terraform validation examples, see the test cases in:
```
../../tests/sql/mysql-database-flags-constraint/
```

These tests include both compliant and non-compliant MySQL instance configurations.

## Notes

- This constraint **only applies to MySQL instances** (versions starting with `MYSQL_`)
- PostgreSQL and SQL Server instances are not affected
- Both flags must be set correctly; missing either flag will cause a violation
- These flags cannot be changed after instance creation without recreating the instance
