# Prevent Instances from Using Default Service Account with Full Scopes

This module creates a custom organization policy constraint that prevents Compute Engine instances from using the default Compute Engine service account with full cloud-platform scopes.

## Security Rationale

**Why this constraint matters:**
- **Maximum Risk Configuration**: Default SA + full cloud-platform scope = unrestricted access to all GCP APIs
- **Privilege Escalation**: Attackers gaining access to the instance can perform any action the project Editor role allows
- **Lateral Movement**: Full scopes enable attackers to pivot to other services and resources
- **Data Exfiltration**: Unrestricted API access allows reading data from all project resources
- **CIS Benchmark**: Explicitly flagged as a critical security misconfiguration in CIS GCP Benchmark
- **Blast Radius**: Compromised instance can impact the entire project and potentially the organization

This is one of the most dangerous misconfigurations in GCP and should be prevented at all costs.

## How It Works

This constraint uses a CEL expression to detect and deny instances using both the default service account AND full cloud-platform scopes.

**Technical Details:**
- **Resource Type**: `compute.googleapis.com/Instance`
- **Action Type**: `DENY` (denies non-compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `has(resource.serviceAccounts) && resource.serviceAccounts.exists(sa, sa.email.matches("^[0-9]+-compute@developer\\.gserviceaccount\\.com$") && sa.scopes.exists(scope, scope == "https://www.googleapis.com/auth/cloud-platform"))`

The constraint checks that:
1. The instance has service accounts attached
2. None of the service accounts are BOTH:
   - The default Compute Engine SA (`PROJECT_NUMBER-compute@developer.gserviceaccount.com`)
   - AND have the full `cloud-platform` scope

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_instance_no_default_sa_full_scopes_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_instance_no_default_sa_full_scopes_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint preventing default service account with full scopes |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a Compute Engine instance using the default service account with full cloud-platform scopes. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create instance with default SA and full scopes
gcloud compute instances create test-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --scopes=cloud-platform
```

**Expected error:**
```
ERROR: (gcloud.compute.instances.create) FAILED_PRECONDITION: Constraint custom.computeInstanceNoDefaultSAFullScopesXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create instance with default SA but limited scopes (still not recommended, but not blocked by this specific constraint)
gcloud compute instances create test-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --scopes=storage-ro,logging-write

# OR create instance with custom SA and full scopes
gcloud iam service-accounts create custom-sa
gcloud compute instances create test-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --service-account=custom-sa@PROJECT_ID.iam.gserviceaccount.com \
  --scopes=cloud-platform
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_compute_instance.compliant_instance
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_compute_instance.violating_instance_default_sa_full_scopes
   ```
