# Prevent Use of Deprecated RSASHA1 Algorithm for DNSSEC

This module creates a custom organization policy constraint that prevents Cloud DNS managed zones from using the deprecated RSASHA1 algorithm for DNSSEC signing.

## Security Rationale

**Why this constraint matters:**
- **Cryptographic Weakness**: RSASHA1 is cryptographically weak and vulnerable to collision attacks
- **Deprecated Algorithm**: Google has deprecated RSASHA1 and requires explicit whitelisting for its use
- **DNS Spoofing**: Weak DNSSEC algorithms increase the risk of DNS cache poisoning and spoofing attacks
- **Compliance**: Security frameworks and best practices mandate use of strong cryptographic algorithms
- **Industry Standards**: NIST and other standards bodies recommend against SHA-1 based algorithms
- **Future-Proofing**: Prevents use of algorithms that may be completely disabled in the future

RSASHA1 should be replaced with stronger algorithms like RSASHA256, RSASHA512, ECDSAP256SHA256, or ECDSAP384SHA384.

## How It Works

This constraint uses a CEL expression to detect and deny managed zones using RSASHA1 for DNSSEC signing.

**Technical Details:**
- **Resource Type**: `dns.googleapis.com/ManagedZone`
- **Action Type**: `DENY` (denies non-compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `has(resource.dnssecConfig) && has(resource.dnssecConfig.defaultKeySpecs) && resource.dnssecConfig.defaultKeySpecs.exists(keySpec, keySpec.algorithm == "rsasha1")`

The constraint checks that:
1. The managed zone has DNSSEC configuration
2. The DNSSEC configuration has key specs defined
3. None of the key specs (KSK or ZSK) use the "rsasha1" algorithm

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_dnssec_no_rsasha1_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_dnssec_no_rsasha1_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint preventing RSASHA1 DNSSEC algorithm |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a Cloud DNS managed zone with RSASHA1 DNSSEC algorithm. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create zone with RSASHA1 algorithm
gcloud dns managed-zones create test-zone \
  --dns-name=test.example.com. \
  --description="Test zone with RSASHA1" \
  --dnssec-state=on \
  --ksk-algorithm=rsasha1 \
  --zsk-algorithm=rsasha1
```

**Expected error:**
```
ERROR: (gcloud.dns.managed-zones.create) FAILED_PRECONDITION: Constraint custom.dnssecNoRSASHA1XXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create zone with strong DNSSEC algorithm
gcloud dns managed-zones create test-zone \
  --dns-name=test.example.com. \
  --description="Test zone with RSASHA256" \
  --dnssec-state=on \
  --ksk-algorithm=rsasha256 \
  --zsk-algorithm=rsasha256
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_dns_managed_zone.compliant_zone
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_dns_managed_zone.violating_zone_rsasha1
   ```
