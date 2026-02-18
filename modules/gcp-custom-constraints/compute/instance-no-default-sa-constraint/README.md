# Prevent Instances from Using Default Service Account

This module creates a custom organization policy constraint that prevents Compute Engine instances from using the default Compute Engine service account.

## Security Rationale

**Why this constraint matters:**
- **Principle of Least Privilege**: The default Compute Engine service account has the Editor role on the project by default, which is overly permissive
- **Blast Radius Reduction**: Compromised instances with default SA can access and modify most project resources
- **Compliance**: Security frameworks like CIS GCP Benchmark require custom service accounts with minimal permissions
- **Identity Management**: Forces explicit service account creation with appropriate IAM roles
- **Audit Trail**: Custom service accounts provide clearer audit logs showing which workloads access which resources
- **Attack Surface**: Default SA with broad permissions increases the attack surface significantly

Using the default service account violates the principle of least privilege and creates unnecessary security risks.

## How It Works

This constraint uses a CEL expression to detect and deny instances using the default Compute Engine service account.

**Technical Details:**
- **Resource Type**: `compute.googleapis.com/Instance`
- **Action Type**: `DENY` (denies non-compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `has(resource.serviceAccounts) && resource.serviceAccounts.exists(sa, sa.email.matches("^[0-9]+-compute@developer\\.gserviceaccount\\.com$"))`

The constraint checks that:
1. The instance has service accounts attached
2. None of the service accounts match the default Compute Engine SA pattern (`PROJECT_NUMBER-compute@developer.gserviceaccount.com`)

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_instance_no_default_sa_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_instance_no_default_sa_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint preventing default service account usage |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a Compute Engine instance using the default service account. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create instance with default service account
gcloud compute instances create test-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro
```

**Expected error:**
```
ERROR: (gcloud.compute.instances.create) FAILED_PRECONDITION: Constraint custom.computeInstanceNoDefaultSAXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# First create a custom service account
gcloud iam service-accounts create custom-sa \
  --display-name="Custom Service Account"

# Create instance with custom service account
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
   terraform apply -target=google_compute_instance.violating_instance_default_sa
   ```
