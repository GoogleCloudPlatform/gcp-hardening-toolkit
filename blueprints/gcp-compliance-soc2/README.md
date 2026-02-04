# GCP Compliance SOC2 Blueprint

This blueprint orchestrates the deployment of custom organization policy constraints required for SOC2 compliance within a Google Cloud environment. It specifically focuses on hardening Cloud SQL database instances across MySQL, PostgreSQL, and SQL Server.

## Overview

The SOC2 compliance blueprint provides a modular, toggle-based approach to enforcing security-critical database flags. It enables organizations to ensure that all Cloud SQL instances—regardless of engine—are configured according to rigorous security standards.

## Security Rationale

**Why this blueprint matters:**
- **Regulatory Compliance**: Helps meet SOC2 trust service criteria related to security, confidentiality, and availability.
- **Data Hardening**: Enforces security best practices (logging, network isolation, access control) automatically.
- **Consistency**: Ensures that every database engine follows the same standards across the organization.
- **Prevention**: Uses `DENY` policies to block insecure configurations before they are created.

## Architecture

```
gcp-compliance-soc2/
├── main.tf                    # Root blueprint orchestrating SQL engine modules
├── variables.tf               # Configuration variables with engine toggles
├── outputs.tf                 # Standardized outputs for constraint names
├── terraform.tfvars.example   # Example configuration template
├── modules/                   # Symlinked or local engine modules
│   └── sql/
│       ├── mysql/             # MySQL specific hardening
│       ├── postgresql/        # PostgreSQL logging & security
│       └── sqlserver/         # SQL Server security flags
│   └── alloydb/           # AlloyDB security constraints
│       ├── logging-constraints/ # Log verbosity & error levels
│       └── private-ip-constraint/ # Network isolation
│   └── dns/               # DNS security constraints
│       ├── dnssec-enabled-constraint/
│       └── dns-policy-logging-constraint/
└── tests/                    # Validation tests with engine-specific examples
```

## Available Constraints

| Engine | Toggle Variable | Implemented Controls |
|---|---|---|
| [MySQL](../../modules/gcp-custom-constraints/sql/mysql/README.md) | `enable_sql_mysql_constraints` | `skip_show_database` |
| [PostgreSQL](../../modules/gcp-custom-constraints/sql/postgresql/README.md) | `enable_sql_postgresql_constraints` | `log_connections`, `log_disconnections`, `log_statement`, `log_min_messages`, etc. |
| [SQL Server](../../modules/gcp-custom-constraints/sql/sqlserver/README.md) | `enable_sql_sqlserver_constraints` | `external scripts enabled`, `3625`, `contained database authentication`, etc. |
| [AlloyDB](../../modules/gcp-custom-constraints/alloydb/private-ip-constraint/README.md) | `enable_alloydb_constraints` | `private IP`, `log_error_verbosity`, `log_min_error_statement`, `log_min_messages` |
| [DNSSEC](../../modules/gcp-custom-constraints/dns/dnssec-enabled-constraint/README.md) | `enable_dns_constraint` | `DNSSEC enabled` |
| [DNS Logging](../../modules/gcp-custom-constraints/dns/dns-policy-logging-constraint/README.md) | `enable_dns_policy_logging_constraint` | `Cloud DNS Policy Logging` |

## Quick Start

### 1. Navigate to the Blueprint

```bash
cd blueprints/gcp-compliance-soc2
```

### 2. Configure Variables

Copy the example configuration:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
parent          = "organizations/123456789012"
project_id      = "your-gcp-project-id"
billing_project = "your-gcp-project-id"

# Toggle engine-specific compliance
enable_sql_mysql_constraints      = true
enable_sql_postgresql_constraints = true
enable_sql_sqlserver_constraints  = true
enable_alloydb_constraints        = true
```

### 3. Deploy Blueprint

```bash
terraform init
terraform plan
terraform apply -parallelism=1
```

## How It Works: Conditional Module Execution

This blueprint uses a **count-based conditional execution pattern**. This allows you to deploy only the security policies relevant to the database engines currently in use or being rolled out in your environment.

### The Count Pattern

Each module in `main.tf` is wrapped in a conditional count:

```hcl
module "sql_mysql_constraints" {
  count  = var.enable_sql_mysql_constraints ? 1 : 0
  source = "../../modules/gcp-custom-constraints/sql/mysql"
  parent = var.parent
}
```

- When `enable_sql_mysql_constraints = true`, the policies are deployed.
- When `false`, the module and its 7-10 associated policies are skipped entirely.

## Troubleshooting

### Error: "invalid_grant" / "reauth related error"

**Issue**: `terraform apply` fails with an OAuth2 invalid grant error or asks for a "Re-auth Related Error (invalid_rapt)".

**Solution**: This typically happens when your GCP session has expired or you are performing high-risk operations (like Organization Policy changes) that require a fresh authentication with a shorter TTL.
Run:
```bash
gcloud auth application-default login
```
This will refresh your Application Default Credentials (ADC) used by Terraform.

### Error 409: Transient Policy Update Failures

> [!IMPORTANT]
> **Always use `-parallelism=1` for organization policy deployments** to avoid Error 409 entirely.

**Issue**: Concurrent updates to the Organization Policy API can cause transient 409 errors.

**Resolution**:
```bash
terraform apply --auto-approve -parallelism=1
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | Parent resource (organizations/id, folders/id, projects/id) | `string` | n/a | yes |
| `project_id` | GCP project ID for API calls | `string` | n/a | yes |
| `billing_project` | GCP billing project ID for quota | `string` | n/a | yes |
| `enable_sql_mysql_constraints` | Enable MySQL SOC2 constraints | `bool` | `true` | no |
| `enable_sql_postgresql_constraints` | Enable PostgreSQL SOC2 constraints | `bool` | `true` | no |
| `enable_sql_sqlserver_constraints` | Enable SQL Server SOC2 constraints | `bool` | `true` | no |
| `enable_alloydb_constraints` | Enable AlloyDB SOC2 constraints | `bool` | `true` | no |
| `enable_dns_constraint` | Enable DNSSEC custom constraint | `bool` | `true` | no |
| `enable_dns_policy_logging_constraint` | Enable Cloud DNS Policy Logging custom constraint | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `mysql_constraint_name` | Name of the MySQL constraint |
| `postgresql_constraint_names` | List of PostgreSQL constraint names |
| `sqlserver_constraint_names` | List of SQL Server constraint names |
| `alloydb_constraint_name` | Name of the AlloyDB constraint |
| `dnssec_constraint_name` | Name of the DNSSEC constraint |
| `dns_policy_logging_constraint_name` | Name of the DNS Policy Logging constraint |

## License

Copyright 2025 Google LLC - Licensed under Apache 2.0
