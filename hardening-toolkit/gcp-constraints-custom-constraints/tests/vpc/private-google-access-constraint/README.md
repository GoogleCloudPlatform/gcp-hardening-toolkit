# Private Google Access Constraint Test

This Terraform configuration tests the `private-google-access-constraint` custom constraint.

## Purpose

This test validates that the organization policy correctly:
- **Allows** creation of subnets with private Google access enabled (compliant)
- **Blocks** creation of subnets without private Google access (non-compliant)

## Prerequisites

> **Important**: Before running this test, ensure the constraint has been deployed.
>
> ```bash
> # From the root gcp-constraints directory
> cd ../../../
> terraform apply
>
> # Return to this test directory
> cd tests/vpc/private-google-access-constraint/
> ```

## Resources

This test creates one VPC network and two subnet resources:

1. **`test_network`**: VPC network for testing (created first)

2. **`compliant_subnetwork`**: Compliant subnet with private Google access enabled
   - Configuration: `private_ip_google_access = true`
   - Expected: Creation should **succeed**

3. **`non_compliant_subnetwork`**: Non-compliant subnet without private Google access
   - Configuration: `private_ip_google_access = false`
   - Expected: Creation should **fail** with constraint violation

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Create VPC Network

```bash
terraform apply -target=google_compute_network.test_network
```

### 3. Test Compliant Resource (should SUCCEED)

```bash
terraform apply -target=google_compute_subnetwork.compliant_subnetwork
```

**Expected outcome**: The subnet is created successfully with private Google access enabled.

### 4. Test Non-Compliant Resource (should FAIL)

```bash
terraform apply -target=google_compute_subnetwork.non_compliant_subnetwork
```

**Expected error**:
```
Error: Error creating Subnetwork: googleapi: Error 412: Precondition not met
Constraint: custom.computePrivateGoogleAccessXXXX violated for projects/PROJECT_ID
```

This failure confirms the constraint is working correctly.

## Cleanup

Remove test resources:

```bash
terraform destroy
```

Or remove specific resources:

```bash
terraform destroy -target=google_compute_subnetwork.compliant_subnetwork -target=google_compute_network.test_network
```
