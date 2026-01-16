# Disallow External Scripts SQL Server Constraint Test

This Terraform configuration tests the `disallow-external-scripts-constraint` custom constraint.

## Purpose

This test validates that the organization policy correctly:
- **Allows** creation of SQL Server instances with external scripts disabled (compliant)
- **Blocks** creation of SQL Server instances with external scripts enabled (non-compliant)

## Prerequisites

> **Important**: Before running this test, ensure the constraint has been deployed.
>
> ```bash
> # From the root gcp-constraints directory
> cd ../../../
> terraform apply
>
> # Return to this test directory
> cd tests/sql/disallow-external-scripts-constraint/
> ```

## Resources

This test creates two SQL Server instance resources:

1. **`compliant_sql_server`**: Compliant SQL Server with external scripts disabled
   - Configuration: `database_flags { name = "external scripts enabled", value = "off" }`
   - Expected: Creation should **succeed**

2. **`violating_sql_server`**: Non-compliant SQL Server with external scripts enabled
   - Configuration: `database_flags { name = "external scripts enabled", value = "on" }`
   - Expected: Creation should **fail** with constraint violation

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Test Compliant Resource (should SUCCEED)

```bash
terraform apply -target=google_sql_database_instance.compliant_sql_server
```

**Expected outcome**: The SQL Server instance is created successfully with external scripts disabled.

**Note**: SQL instance creation takes 5-10 minutes.

### 3. Test Non-Compliant Resource (should FAIL)

```bash
terraform apply -target=google_sql_database_instance.violating_sql_server
```

**Expected error**:
```
Error: Error creating Instance: googleapi: Error 412: Precondition not met
Constraint: custom.sqlDisallowExternalScriptsXXXX violated for projects/PROJECT_ID
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
terraform destroy -target=google_sql_database_instance.compliant_sql_server
```
