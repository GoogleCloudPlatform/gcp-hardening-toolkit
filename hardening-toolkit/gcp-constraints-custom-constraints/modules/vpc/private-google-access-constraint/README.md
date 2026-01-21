# Enforce Private Google Access Constraint

This module creates a custom organization policy constraint that ensures all VPC network subnets have private Google access enabled.

## Security Rationale

**Why this constraint matters:**
- **Eliminates Public IP Exposure**: VMs can access Google APIs without requiring external IP addresses
- **Reduces Attack Surface**: Prevents internet-facing VMs from being directly accessible
- **Cost Savings**: Eliminates egress charges for Google API traffic
- **Compliance**: Required for many security frameworks that mandate private networking
- **Defense in Depth**: Adds an additional layer of network isolation

Without private Google access, VMs need external IPs to reach Google services, exposing them to internet-based attacks.

## How It Works

This constraint uses a CEL expression to verify that the `privateIpGoogleAccess` field is set to `true` on all subnets.

**Technical Details:**
- **Resource Type**: `compute.googleapis.com/Subnetwork`
- **Action Type**: `ALLOW` (only allows compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.privateIpGoogleAccess == true`

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_vpc_private_google_access_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_vpc_private_google_access_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for private Google access |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a subnet without private Google access enabled. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create subnet without private Google access
gcloud compute networks subnets create test-subnet-no-pga \
  --network=default \
  --region=us-central1 \
  --range=10.0.1.0/24
```

**Expected error:**
```
ERROR: (gcloud.compute.networks.subnets.create) HTTPError 412: Constraint custom.computePrivateGoogleAccessXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create subnet with private Google access enabled
gcloud compute networks subnets create test-subnet-with-pga \
  --network=default \
  --region=us-central1 \
  --range=10.0.2.0/24 \
  --enable-private-ip-google-access
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_compute_subnetwork.compliant_subnetwork
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_compute_subnetwork.violating_pga_subnet
   ```
