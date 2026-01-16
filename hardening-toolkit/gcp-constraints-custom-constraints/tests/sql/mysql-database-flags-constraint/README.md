# MySQL Database Flags Constraint Test

This Terraform configuration tests the `mysql-database-flags-constraint` custom constraint.

## Purpose

This test validates that the organization policy correctly:
- **Allows** creation of MySQL instances with required security flags (compliant)
- **Blocks** creation of MySQL instances without required security flags (non-compliant)

## Prerequisites

> **Important**: Before running this test, ensure the constraint has been deployed.
>
> ```bash
> # From the root gcp-constraints directory
> cd ../../../
> terraform apply
>
> # Return to this test directory
> cd tests/sql/mysql-database-flags-constraint/
> ```

## Resources

This test creates two MySQL database instance resources:

1. **`compliant_mysql`**: Compliant MySQL instance with required flags
   - Configuration:
     - `skip_show_database = on`
     - `local_infile = off`
   - Expected: Creation should **succeed**

2. **`violating_mysql`**: Non-compliant MySQL instance with incorrect flags
   - Configuration: `local_infile = on` (violates policy)
   - Expected: Creation should **fail** with constraint violation

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Test Compliant Resource (should SUCCEED)

```bash
terraform apply -target=google_sql_database_instance.compliant_mysql
```

**Expected outcome**: The MySQL instance is created successfully with required security flags.

**Note**: SQL instance creation takes 5-10 minutes.

### 3. Test Non-Compliant Resource (should FAIL)

```bash
terraform apply -target=google_sql_database_instance.violating_mysql
```

**Expected error**:
```
Error: Error creating Instance: googleapi: Error 412: Precondition not met
Constraint: custom.sqlMysqlDatabaseFlagsXXXX violated for projects/PROJECT_ID
```

This failure confirms the constraint is working correctly.

## Cleanup

Remove test resources:

```bash
terraform destroy
```

**Note**: SQL instance deletion takes 5-10 minutes.

Or remove specific resources:

```bash
terraform destroy -target=google_sql_database_instance.compliant_mysql
```
