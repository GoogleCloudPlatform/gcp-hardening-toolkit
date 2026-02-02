# Enforce Cloud DNS Policy Logging Constraint

This module creates a custom organization policy constraint that ensures all Cloud DNS policies have logging enabled for security monitoring, troubleshooting, and compliance purposes.

## Security Rationale

**Why this constraint matters:**
- **Security Monitoring**: DNS query logs help detect DNS tunneling, data exfiltration, and command-and-control communications
- **Troubleshooting**: Essential for diagnosing DNS resolution issues and understanding query patterns
- **Compliance**: Required for many security frameworks (SOC2, PCI-DSS, HIPAA) to maintain DNS activity logs
- **Threat Detection**: Enables detection of malicious domains, DGA (Domain Generation Algorithm) activity, and DNS-based attacks
- **Audit Trail**: Provides visibility into DNS queries for forensic analysis and incident response

Without DNS logging, you have no visibility into DNS queries, making it impossible to detect DNS-based attacks or troubleshoot resolution issues.

## How It Works

This constraint uses a CEL (Common Expression Language) expression to check that the `enableLogging` field is set to `true` on all DNS policies.

**Technical Details:**
- **Resource Type**: `dns.googleapis.com/Policy`
- **Action Type**: `DENY` (blocks policies without logging)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `!has(resource.enableLogging) || resource.enableLogging == false`

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_dns_policy_logging_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_dns_policy_logging_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for DNS policy logging |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a DNS policy without logging enabled. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create a DNS policy without logging
gcloud dns policies create test-policy-no-logging \
  --networks=default \
  --description="Test policy without logging"
```

**Expected error:**
```
ERROR: (gcloud.dns.policies.create) Could not fetch resource:
 - Constraint custom.dnsPolicyLoggingXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create a DNS policy WITH logging enabled
gcloud dns policies create test-policy-with-logging \
  --networks=default \
  --description="Test policy with logging" \
  --enable-logging
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_dns_policy.compliant_policy
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_dns_policy.violating_policy
   ```

## Notes

- DNS policy logging can generate significant log volume in high-query environments
- Logs are stored in Cloud Logging and incur storage costs
- DNS policies control DNS resolution behavior for VPC networks
- Logging includes query name, query type, response code, and client IP
- Consider using log sampling or filtering for very high-volume environments
