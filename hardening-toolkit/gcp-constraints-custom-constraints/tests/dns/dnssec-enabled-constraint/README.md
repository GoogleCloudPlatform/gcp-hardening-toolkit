# DNSSEC Enabled Constraint Test

This Terraform configuration tests the `dnssec-enabled-constraint` custom constraint.

## Purpose

This test validates that the organization policy correctly:
- **Allows** creation of DNS managed zones with DNSSEC enabled (compliant)
- **Blocks** creation of public DNS managed zones without DNSSEC (non-compliant)

## Prerequisites

> **Important**: Before running this test, ensure the constraint has been deployed.
>
> ```bash
> # From the root gcp-constraints directory
> cd ../../../
> terraform apply
>
> # Return to this test directory
> cd tests/dns/dnssec_disabled/
> ```

## Resources

This test creates two DNS managed zone resources:

1. **`compliant_zone`**: Compliant DNS zone with DNSSEC enabled
   - Configuration: `dnssec_config { state = "on" }`
   - Expected: Creation should **succeed**

2. **`violating_zone`**: Non-compliant public DNS zone with DNSSEC disabled
   - Configuration: `dnssec_config { state = "off" }`
   - Expected: Creation should **fail** with constraint violation

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Test Compliant Resource (should SUCCEED)

```bash
terraform apply -target=google_dns_managed_zone.compliant_zone
```

**Expected outcome**: The DNS zone is created successfully with DNSSEC enabled.

### 3. Test Non-Compliant Resource (should FAIL)

```bash
terraform apply -target=google_dns_managed_zone.violating_zone
```

**Expected error**:
```
Error: Error creating ManagedZone: googleapi: Error 412: Precondition not met
Constraint: custom.dnssecEnabledXXXX violated for projects/PROJECT_ID
```

This failure confirms the constraint is working correctly.

## Cleanup

Remove test resources:

```bash
terraform destroy
```

Or remove specific resources:

```bash
terraform destroy -target=google_dns_managed_zone.compliant_zone
```
