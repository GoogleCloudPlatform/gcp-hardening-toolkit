# GCP Compliance SOC2 Blueprint

This blueprint orchestrates the deployment of **built-in GCP organization policies** and **custom organization policy constraints** required for SOC2 compliance within a Google Cloud environment.

## Overview

The SOC2 compliance blueprint provides a comprehensive, modular approach to enforcing security controls across your GCP organization:

- **Built-in Organization Policies**: Enforces 10 foundational GCP security constraints including compute security, storage protection, database isolation, and encryption requirements
- **Custom Constraints**: Provides granular control over Cloud SQL, AlloyDB, DNS, BigQuery, and Compute Engine configurations with engine-specific security flags

## Security Rationale

**Why this blueprint matters:**
- **Regulatory Compliance**: Helps meet SOC2 trust service criteria related to security, confidentiality, and availability.
- **Data Hardening**: Enforces security best practices (logging, network isolation, access control) automatically.
- **Consistency**: Ensures that every database engine follows the same standards across the organization.
- **Prevention**: Uses `DENY` policies to block insecure configurations before they are created.

## Architecture

```
gcp-compliance-soc2/
├── org-policies.tf            # Built-in GCP organization policies (10 constraints)
├── constraints.tf             # Custom organization policy constraints
├── variables.tf               # Configuration variables with toggles
├── outputs.tf                 # Standardized outputs for constraint names
├── terraform.tfvars.example   # Example configuration template
└── tests/                     # Validation tests

Referenced Modules (from ../../modules/):
├── gcp-org-policies/          # Built-in organization policies module
└── gcp-custom-constraints/    # Custom organization policy constraints
    ├── sql/
    │   ├── mysql/             # MySQL specific hardening
    │   ├── postgresql/        # PostgreSQL logging & security
    │   └── sqlserver/         # SQL Server security flags
    ├── alloydb/               # AlloyDB security constraints
    │   ├── logging-constraints/
    │   └── private-ip-constraint/
    ├── dns/                   # DNS security constraints
    │   ├── dnssec-enabled-constraint/
    │   ├── dns-policy-logging-constraint/
    │   └── dnssec-no-rsasha1-constraint/
    ├── bigquery/              # BigQuery security constraints
    │   └── bq-dataset-cmek-constraint/
    ├── dataproc/              # Dataproc security constraints
    │   └── dataproc-cmek-constraint/
    └── compute/               # Compute security constraints
        ├── instance-no-default-sa-constraint/
        ├── instance-no-default-sa-full-scopes-constraint/
        └── instance-no-ip-forwarding-constraint/
```

## Built-in Organization Policies

The blueprint enforces 10 foundational GCP built-in organization policy constraints for SOC2 compliance:

| Constraint | Type | Enforcement | SOC2 Relevance |
|------------|------|-------------|----------------|
| `compute.requireVpcFlowLogs` | List | Requires VPC Flow Logs on all subnets | Network monitoring, CC6.2 |
| `storage.uniformBucketLevelAccess` | Boolean | Enforced | Access control, CC6.1 |
| `sql.restrictPublicIp` | Boolean | Enforced | Database security, CC6.1 |
| `storage.publicAccessPrevention` | Boolean | Enforced | Data protection, CC6.2 |
| `compute.restrictNonConfidentialComputing` | List | Requires confidential computing | Data encryption, CC6.6 |
| `compute.skipDefaultNetworkCreation` | Boolean | Enforced | Network security |
| `gcp.restrictNonCmekServices` | List | Requires CMEK encryption | Encryption control, CC6.6 |
| `compute.requireOsLogin` | Boolean | Enforced | Access control, CC6.1 |
| `compute.disableSerialPortAccess` | Boolean | Enforced | Access control |
| `compute.vmExternalIpAccess` | List | Denies external IPs | Network security |

**Configuration**: These policies are managed through the `gcp-org-policies` module and can be toggled using `enable_soc2_org_policies = true` (default).

## Custom Constraints

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
| `enable_soc2_org_policies` | Enable built-in organization policies for SOC2 | `bool` | `true` | no |
| `organization_id` | Organization ID (format: organizations/ID) | `string` | `""` | no |
| `parent_folder` | Folder ID (format: folders/ID) | `string` | `""` | no |
| `domains_to_allow` | List of allowed domains for IAM policy members | `list(string)` | `[]` | no |
| `allowed_resource_locations` | List of allowed resource locations | `list(string)` | `["us-east4", "us-central1"]` | no |
| `trusted_image_projects` | List of allowed trusted image projects | `list(string)` | `[]` | no |
| `essential_contacts_domains_to_allow` | List of allowed domains for essential contacts | `list(string)` | `[]` | no |

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
