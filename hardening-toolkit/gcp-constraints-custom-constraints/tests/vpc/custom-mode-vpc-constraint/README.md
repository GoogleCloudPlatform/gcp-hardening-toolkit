# VPC Custom Mode Constraint Test

This Terraform configuration tests the `custom-mode-vpc-constraint` custom constraint.

## Purpose

This test validates that the organization policy correctly:
- **Allows** creation of custom mode VPC networks (compliant)
- **Blocks** creation of auto mode VPC networks (non-compliant)

## Prerequisites

> **Important**: Before running this test, ensure the constraint has been deployed.
>
> ```bash
> # From the root gcp-constraints directory
> cd ../../../
> terraform apply
>
> # Return to this test directory
> cd tests/vpc/custom-mode-vpc-constraint/
> ```

## Resources

This test creates VPC network resources:

1. **`custom_mode_vpc`**: Compliant custom mode VPC network
   - Configuration: `auto_create_subnetworks = false`
   - Includes a manually created subnet (`custom_subnet`)
   - Expected: Creation should **succeed**

2. **`auto_mode_vpc`**: Non-compliant auto mode VPC network
   - Configuration: `auto_create_subnetworks = true`
   - Expected: Creation should **fail** with constraint violation

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Test Compliant Resource (should SUCCEED)

```bash
terraform apply -target=google_compute_network.custom_mode_vpc -target=google_compute_subnetwork.custom_subnet
```

**Expected outcome**: The custom mode VPC and subnet are created successfully.

### 3. Test Non-Compliant Resource (should FAIL)

```bash
terraform apply -target=google_compute_network.auto_mode_vpc
```

**Expected error**:
```
Error: Error creating Network: googleapi: Error 412: Precondition not met
Constraint: custom.computeCustomModeVpcXXXX violated for projects/PROJECT_ID
```

This failure confirms the constraint is working correctly.

## Cleanup

Remove test resources:

```bash
terraform destroy
```

Or remove specific resources:

```bash
terraform destroy -target=google_compute_subnetwork.custom_subnet -target=google_compute_network.custom_mode_vpc
```
