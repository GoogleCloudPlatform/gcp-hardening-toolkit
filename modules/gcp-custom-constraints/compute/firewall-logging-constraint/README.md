# Enforce VPC Firewall Rule Logging Constraint

This module creates a custom organization policy constraint that ensures all VPC firewall rules have logging enabled for security monitoring and audit purposes.

## Security Rationale

**Why this constraint matters:**
- **Security Monitoring**: Firewall logs are essential for detecting unauthorized access attempts and security threats
- **Audit Trail**: Provides visibility into network traffic patterns and policy enforcement
- **Compliance**: Required for many security frameworks (SOC2, PCI-DSS, HIPAA) to maintain network activity logs
- **Incident Response**: Critical for investigating security incidents and understanding attack patterns
- **Troubleshooting**: Helps diagnose connectivity issues and validate firewall rule effectiveness

Without logging enabled, you have no visibility into which firewall rules are being triggered, making it impossible to detect attacks or troubleshoot network issues.

## How It Works

This constraint uses a CEL (Common Expression Language) expression to check that the `logConfig` field exists and is enabled on all VPC firewall rules.

**Technical Details:**
- **Resource Type**: `compute.googleapis.com/Firewall`
- **Action Type**: `DENY` (blocks rules without logging)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `!has(resource.logConfig) || resource.logConfig.enable == false`

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_firewall_policy_logging_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_firewall_policy_logging_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for VPC firewall logging |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a VPC firewall rule without logging enabled. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create a firewall rule without logging
gcloud compute firewall-rules create test-rule-no-logging \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0
```

**Expected error:**
```
ERROR: (gcloud.compute.firewall-rules.create) Could not fetch resource:
 - Constraint custom.computeFirewallLoggingXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create a firewall rule WITH logging enabled
gcloud compute firewall-rules create test-rule-with-logging \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --enable-logging
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_compute_firewall.compliant_rule
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_compute_firewall.violating_rule
   ```

## Notes

- Firewall logging can generate significant log volume in high-traffic environments
- Logs are stored in Cloud Logging and incur storage costs
- You can configure log metadata level: `INCLUDE_ALL_METADATA` or `EXCLUDE_ALL_METADATA`
- This constraint applies to VPC firewall rules (classic), not Firewall Policies
- Logging metadata includes: connection details, rule matched, action taken, and timestamps
