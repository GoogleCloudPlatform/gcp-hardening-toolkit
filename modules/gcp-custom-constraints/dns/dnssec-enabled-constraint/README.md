# DNSSEC Enabled Custom Constraint

This module creates a custom organization policy constraint that ensures DNSSEC (Domain Name System Security Extensions) is enabled for all public Cloud DNS managed zones.

## Security Rationale

**Why this constraint matters:**
- **Prevents DNS Spoofing**: DNSSEC cryptographically signs DNS records to prevent tampering
- **Protects Against Cache Poisoning**: Ensures DNS responses haven't been modified in transit
- **Authentication**: Validates that DNS responses come from authoritative name servers
- **Data Integrity**: Guarantees DNS data hasn't been altered
- **Compliance**: Required for many government and financial sector regulations

Without DNSSEC, attackers can redirect users to malicious sites by poisoning DNS caches or intercepting DNS queries.

## How It Works

This constraint uses a CEL expression to verify that DNSSEC is enabled on all **public** Cloud DNS managed zones.

**Technical Details:**
- **Resource Type**: `dns.googleapis.com/ManagedZone`
- **Action Type**: `DENY` (blocks zones without DNSSEC)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.visibility == "PUBLIC" && (resource.dnssecConfig.state in ["ON", "TRANSFER"] == false)`
- **Scope**: Only applies to public zones; private zones are exempt

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_dns_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_dns_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for DNSSEC |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a Cloud DNS managed zone with DNSSEC disabled. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create a public managed zone with DNSSEC disabled
gcloud dns managed-zones create test-zone-no-dnssec \
  --description="Test zone without DNSSEC" \
  --dns-name="test-zone.example.com." \
  --dnssec-state=off
```

**Expected error:**
```
ERROR: (gcloud.dns.managed-zones.create) HTTPError 412: Constraint custom.dnssecEnabledXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create a public managed zone with DNSSEC enabled
gcloud dns managed-zones create test-zone-with-dnssec \
  --description="Test zone with DNSSEC" \
  --dns-name="test-zone.example.com." \
  --dnssec-state=on
```

### Private zones are exempt (should SUCCEED):

```bash
# Private zones are not affected by this constraint
gcloud dns managed-zones create test-private-zone \
  --description="Private zone" \
  --dns-name="internal.example.com." \
  --visibility=private \
  --networks=default
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
   terraform apply -target=google_dns_managed_zone.violating_zone
   ```
