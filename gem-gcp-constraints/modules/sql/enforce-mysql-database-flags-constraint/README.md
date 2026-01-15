# Enforce MySQL Database Flags

This module creates custom organization policies to enforce that all new and updated Cloud SQL for MySQL instances have the following database flags set correctly:

- `skip_show_database`: must be `on`
- `local_infile`: must be `off`

## Usage

```hcl
module "enforce_mysql_database_flags" {
  source = "./modules/sql/enforce-mysql-database-flags-constraint"

  parent = "organizations/123456789012"
}
```
