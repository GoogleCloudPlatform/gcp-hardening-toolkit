# Enforce Custom Mode VPC Constraint

This module creates a custom organization policy constraint that ensures all VPC networks are created in custom mode rather than auto mode.

## Security Rationale

**Why this constraint matters:**
- **Network Control**: Custom mode gives you full control over subnet creation and IP ranges
- **Prevents Automatic Subnets**: Auto mode creates subnets in every region automatically, increasing attack surface
- **IP Range Management**: Allows careful planning of IP address spaces to avoid conflicts
- **Least Privilege**: Only create subnets in regions you actually use
- **Security Segmentation**: Enables better network segmentation and isolation

Auto mode VPCs create subnets in all regions by default, which violates the principle of least privilege and creates unnecessary network exposure.

## How It Works

This constraint uses a CEL expression to verify that VPCs are not created in auto mode.

**Technical Details:**
- **Resource Type**: `compute.googleapis.com/Network`
- **Action Type**: `DENY` (blocks auto mode VPCs)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.autoCreateSubnetworks == false`

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_vpc_custom_mode_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_vpc_custom_mode_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for custom mode VPC |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a VPC network in auto mode. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create an auto-mode VPC network
gcloud compute networks create test-auto-network \
  --subnet-mode=auto
```

**Expected error:**
```
ERROR: (gcloud.compute.networks.create) HTTPError 412: Constraint custom.computeCustomModeVpcXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create a custom-mode VPC network
gcloud compute networks create test-custom-network \
  --subnet-mode=custom

# Then create subnets manually as needed
gcloud compute networks subnets create test-subnet \
  --network=test-custom-network \
  --region=us-central1 \
  --range=10.0.1.0/24
```

### Test with Terraform (should FAIL):

```hcl
resource "google_compute_network" "test_auto" {
  name                    = "test-auto-network"
  auto_create_subnetworks = true  # This will violate the constraint
}
```

### Terraform-based Testing

For complete Terraform validation examples, see the test cases in:
```
../../tests/vpc/custom-mode-vpc-constraint/
```

These tests include both compliant and non-compliant VPC configurations.

## Notes

- Existing auto mode VPCs are not affected; this only applies to new VPCs
- Custom mode VPCs require manual subnet creation
- You cannot convert an auto mode VPC to custom mode (one-way conversion only)
- Custom mode is recommended for production environments
