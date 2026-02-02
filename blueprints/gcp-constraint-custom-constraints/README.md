# GCP Organization Policy Custom Constraints

A comprehensive Terraform toolkit for enforcing security and compliance best practices across Google Cloud Platform using custom organization policy constraints.

## Overview

This module provides a modular, toggle-based approach to deploying GCP organization policy custom constraints. Each constraint uses Common Expression Language (CEL) to enforce specific security requirements at the organization, folder, or project level.

## Architecture

```
gcp-custom-constraints/
├── main.tf                    # Root module orchestrating all constraints
├── variables.tf               # Configuration variables with feature toggles
├── terraform.tfvars.example   # Example configuration template
├── modules/                   # Individual constraint modules
│   ├── compute/              # Compute Engine constraints
│   ├── dns/                  # Cloud DNS constraints
│   ├── storage/              # Cloud Storage constraints
│   └── vpc/                  # VPC networking constraints
└── tests/                    # Validation tests with compliant/non-compliant examples
```

## Available Constraints

| Constraint | Toggle Variable | Test Directory |
|---|---|---|
| [DNSSEC Enabled](./modules/dns/dnssec-enabled-constraint/README.md) | `enable_dns_constraint` | `tests/dns/dnssec-enabled-constraint/` |
| [DNS Policy Logging](./modules/dns/dns-policy-logging-constraint/README.md) | `enable_dns_policy_logging_constraint` | `tests/compliant/` and `tests/non-compliant/` |
| [Bucket Versioning](./modules/storage/bucket-versioning-constraint/README.md) | `enable_storage_constraint` | `tests/storage/bucket-versioning-constraint/` |
| [Private Google Access](./modules/vpc/private-google-access-constraint/README.md) | `enable_vpc_private_google_access_constraint` | `tests/vpc/private-google-access-constraint/` |
| [Custom Mode VPC](./modules/vpc/custom-mode-vpc-constraint/README.md) | `enable_vpc_custom_mode_constraint` | `tests/vpc/custom-mode-vpc-constraint/` |
| [Backend Service Logging](./modules/compute/backend-service-logging-constraint/README.md) | `enable_compute_backend_service_logging_constraint` | `tests/compute/backend-service-logging-constraint/` |
| [VPC Firewall Logging](./modules/compute/firewall-logging-constraint/README.md) | `enable_firewall_policy_logging_constraint` | `tests/compliant/` and `tests/non-compliant/` |
| [VPC Firewall No Public Access](./modules/compute/firewall-no-public-access-constraint/README.md) | `enable_firewall_no_public_access_constraint` | `tests/compliant/` and `tests/non-compliant/` |
| [No Public Bindings](./modules/iam/no-public-bindings-constraint/README.md) | `enable_iam_no_public_bindings_constraint` | `tests/compliant/` and `tests/non-compliant/` |
| [Cloud SQL SSL Enforcement](./modules/sql/sql-ssl-enforcement-constraint/README.md) | `enable_sql_ssl_enforcement_constraint` | `tests/compliant/` and `tests/non-compliant/` |



## Quick Start

### 1. Navigate to the Directory

```bash
cd /path/to/hardening-toolkit/gcp-custom-constraints
```

### 2. Configure Variables

Copy the example configuration:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
```hcl
parent          = "organizations/123456789012"  # or folders/xxx or projects/xxx
project_id      = "your-gcp-project-id"
billing_project = "your-gcp-project-id"

# Enable/disable specific constraints
enable_dns_constraint                              = true
enable_dns_policy_logging_constraint               = true
enable_storage_constraint                          = true
enable_vpc_private_google_access_constraint        = true
enable_vpc_custom_mode_constraint                  = true
enable_compute_backend_service_logging_constraint  = true
enable_firewall_policy_logging_constraint          = true
enable_firewall_no_public_access_constraint        = true
```

### 3. Deploy Constraints

```bash
terraform init
terraform plan
terraform apply
```

The `main.tf` file will automatically call all the constraint modules based on your configuration.

### 4. Verify Deployment

Check that constraints are active:
```bash
gcloud org-policies list --organization=YOUR_ORG_ID
```

## How It Works: Conditional Module Execution

This toolkit uses a **count-based conditional execution pattern** to provide flexibility in which constraints are deployed. This is crucial because:

- **Organizations have different compliance requirements**: Not every organization needs all constraints
- **Phased rollouts**: You can enable constraints gradually to minimize disruption
- **Environment-specific policies**: Dev environments may need different constraints than production

### The Count Pattern

Each module in `main.tf` uses a `count` parameter tied to a boolean variable:

```hcl
module "dnssec_enabled_constraint" {
  count  = var.enable_dns_constraint ? 1 : 0  # Only creates if true
  source = "./modules/dns/dnssec-enabled-constraint"
  parent = var.parent
}
```

**How it works:**
- When `enable_dns_constraint = true` in `terraform.tfvars`, `count = 1` → module is created
- When `enable_dns_constraint = false` in `terraform.tfvars`, `count = 0` → module is skipped entirely

This means you can **selectively deploy only the constraints your organization needs** by simply toggling variables in `terraform.tfvars`.

## Usage Examples

### Example 1: Organization-Wide Full Deployment

Deploy all constraints across the entire organization:

**terraform.tfvars:**
```hcl
parent          = "organizations/123456789012"
project_id      = "security-controls-project"
billing_project = "security-controls-project"

# Enable all constraints
enable_dns_constraint                              = true
enable_storage_constraint                          = true
enable_vpc_private_google_access_constraint        = true
enable_vpc_custom_mode_constraint                  = true
enable_compute_backend_service_logging_constraint  = true
```

**Deploy:**
```bash
cd gcp-custom-constraints
terraform apply
```

### Example 2: Folder-Scoped Selective Deployment

Deploy only critical constraints to a development folder:

**terraform.tfvars:**
```hcl
parent          = "folders/987654321098"
project_id      = "dev-security-project"
billing_project = "dev-security-project"

# Enable only critical constraints for dev environment
enable_dns_constraint     = true
enable_storage_constraint = true

# Disable others for development flexibility
enable_vpc_private_google_access_constraint        = false
enable_vpc_custom_mode_constraint                  = false
enable_compute_backend_service_logging_constraint  = false
```

**Deploy:**
```bash
cd gcp-custom-constraints
terraform apply
```

### Example 3: Phased Rollout

Start with low-impact constraints, then gradually enable more:

**Phase 1 - terraform.tfvars:**
```hcl
parent = "organizations/123456789012"

# Start with logging and versioning only
enable_storage_constraint                          = true
enable_compute_backend_service_logging_constraint  = true

# Disable enforcement constraints initially
enable_dns_constraint                              = false
enable_vpc_private_google_access_constraint        = false
enable_vpc_custom_mode_constraint                  = false
```

**Phase 2 - Update terraform.tfvars after monitoring:**
```hcl
# Enable network security constraints
enable_vpc_private_google_access_constraint        = true
enable_vpc_custom_mode_constraint                  = true
```

**Apply changes:**
```bash
terraform apply  # Only creates newly enabled modules
```

## Testing

The testing suite has been simplified into two primary categories to allow for rapid validation of the entire toolkit:

### Compliant Tests (`tests/compliant/`)
Contains resources that strictly follow the policies. Use these to verify that the constraints do **not** block legitimate, secure resource creation.
```bash
cd tests/compliant
terraform init
terraform apply
```

### Non-Compliant Tests (`tests/non-compliant/`)
Contains resources that intentionally violate the policies. Use these to verify that the constraints are successfully blocking insecure configurations.
```bash
cd tests/non-compliant
terraform init
terraform apply
```

Expected output for violation:
```
Error: Error creating Resource: googleapi: Error 412: Precondition not met
Constraint: custom.constraintNameXXXX violated
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach policies to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |
| `project_id` | GCP project ID for API calls | `string` | n/a | yes |
| `billing_project` | GCP billing project ID for quota | `string` | n/a | yes |
| `enable_dns_constraint` | Enable DNSSEC custom constraint | `bool` | `true` | no |
| `enable_dns_policy_logging_constraint` | Enable Cloud DNS policy logging constraint | `bool` | `true` | no |
| `enable_storage_constraint` | Enable bucket versioning constraint | `bool` | `true` | no |
| `enable_vpc_private_google_access_constraint` | Enable private Google access constraint | `bool` | `true` | no |
| `enable_vpc_custom_mode_constraint` | Enable custom mode VPC constraint | `bool` | `true` | no |
| `enable_compute_backend_service_logging_constraint` | Enable backend service logging constraint | `bool` | `true` | no |
| `enable_firewall_policy_logging_constraint` | Enable VPC firewall rule logging constraint | `bool` | `true` | no |
| `enable_firewall_no_public_access_constraint` | Enable VPC firewall no public access (0.0.0.0/0) constraint | `bool` | `true` | no |
| `enable_iam_no_public_bindings_constraint` | Enable IAM no public bindings (allUsers, allAuthenticatedUsers) constraint | `bool` | `true` | no |
| `enable_sql_ssl_enforcement_constraint` | Enable Cloud SQL SSL Enforcement constraint | `bool` | `true` | no |



## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| google | >= 5.45.2 |
| time | ~> 0.11.1 |
| random | >= 3.0.0 |

## Permissions Required

The service account or user deploying these constraints needs:
- `orgpolicy.policies.create`
- `orgpolicy.policies.update`
- `orgpolicy.customConstraints.create`
- `orgpolicy.customConstraints.update`

Typically granted via:
- `roles/orgpolicy.policyAdmin` at the organization/folder/project level

## Troubleshooting

### Constraint Not Enforcing

**Issue**: Resources are created despite constraint being deployed

**Solutions**:
1. Verify constraint is active:
   ```bash
   gcloud org-policies describe CONSTRAINT_NAME --organization=ORG_ID
   ```
2. Check for inheritance conflicts at lower levels
3. Wait 5-10 minutes for policy propagation

### 412 Precondition Failed During Apply

**Issue**: Terraform apply fails when creating constraints

**Solutions**:
1. Ensure you have `orgpolicy.policyAdmin` role
2. Check if constraint with same name already exists
3. Verify parent resource format is correct

### Random Suffix Conflicts

**Issue**: Constraint names conflict on re-deployment

**Solutions**:
1. Import existing constraints before destroying:
   ```bash
   terraform import module.dnssec_enabled_constraint.google_org_policy_custom_constraint.dnssec_enabled organizations/ORG_ID/customConstraints/custom.dnssecEnabledXXXX
   ```
2. Or manually delete old constraints before redeploying

### Error 409: Transient Policy Update Failures

> [!IMPORTANT]
> This is a **known, transient issue** with the GCP Organization Policy API when multiple policies are updated concurrently. It is largely cosmetic and does not indicate a failure in policy enforcement.

**Issue**: `terraform apply` fails with error:
```
Error: Error updating Policy "organizations/ORG_ID/policies/POLICY_NAME": googleapi: Error 409: The operation was aborted. # pragma: allowlist secret
```
**Root Cause**:
- The GCP Organization Policy API returns Error 409 when multiple policy resources are updated simultaneously
- This often occurs when Terraform normalizes the `enforce` field from `"TRUE"` (string) to `true` (boolean) in the state
- The API has rate limiting and concurrency restrictions that can cause transient failures
- **The policies are typically still enforced correctly** despite the error

**Symptoms**:
- Error appears during `terraform apply` after successful `terraform refresh`
- Only affects one or a few policies out of many being updated
- The error is inconsistent and may not occur on subsequent runs
- Plan shows only cosmetic changes like `enforce = "TRUE" -> "true"`

**Resolution** (in order of preference):

1. **Use `-parallelism=1` flag** (✅ **Recommended - Tested & Verified**):
   ```bash
   terraform apply --auto-approve -parallelism=1
   ```
   This forces Terraform to update policies sequentially, completely avoiding concurrent API calls and eliminating the Error 409 issue. This approach has been tested and confirmed to work reliably.

2. **Run `terraform refresh`**:
   ```bash
   terraform refresh
   ```
   This updates the Terraform state to match the deployed policies without making changes. Use this if you've already encountered the error.

3. **Re-run `terraform apply`**:
   ```bash
   terraform apply --auto-approve
   ```
   The API often succeeds on subsequent attempts, though the error may recur.

4. **Target the specific failing policy**:
   ```bash
   terraform apply -target=module.CONSTRAINT_NAME[0].google_org_policy_policy.POLICY_NAME
   ```
   This isolates the update to a single policy, avoiding concurrent API calls.

5. **Ignore if policies are enforcing correctly**:
   - Verify policies are active using `gcloud org-policies list --organization=ORG_ID`
   - If enforcement is working, this is purely a state synchronization issue
   - The error will likely resolve itself on the next `terraform apply`

**Prevention** (✅ **Highly Recommended**):

> [!TIP]
> **Always use `-parallelism=1` for organization policy deployments** to avoid Error 409 entirely. While this increases deployment time, it ensures reliable, error-free execution.

```bash
# Recommended for apply
terraform apply --auto-approve -parallelism=1

# Recommended for destroy
terraform destroy --auto-approve -parallelism=1
```

**Why this works**:
- The GCP Organization Policy API has strict concurrency limitations
- Sequential updates (parallelism=1) prevent simultaneous policy modifications
- The `time_sleep` resources in each module provide delays, but cannot fully prevent concurrent API calls when Terraform's default parallelism (10) is used
- Testing confirms that `-parallelism=1` eliminates the Error 409 issue completely

## Best Practices

1. **Start Small**: Deploy to a test folder first before organization-wide rollout
2. **Gradual Rollout**: Enable constraints one at a time to identify conflicts
3. **Document Exemptions**: Use policy exemptions sparingly and document reasons
4. **Monitor Impact**: Review Cloud Asset Inventory for affected resources
5. **Test Thoroughly**: Use the provided test cases before production deployment

## Contributing

When adding new constraints:
1. Create module in `modules/{service}/{constraint-name}/`
2. Follow existing module pattern (constraint + policy + time_sleep)
3. Add corresponding test in `tests/{service}/{constraint-name}/`
4. Include README with validation commands
5. Update this main README with constraint description

## License

Copyright 2025 Google LLC - Licensed under Apache 2.0
