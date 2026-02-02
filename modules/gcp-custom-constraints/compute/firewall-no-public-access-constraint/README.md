# Prevent VPC Firewall Rules with Public Access (0.0.0.0/0)

This module creates a custom organization policy constraint that prevents the creation of VPC firewall rules that allow traffic from or to any IP address (0.0.0.0/0), enforcing the principle of least privilege and reducing attack surface.

## Security Rationale

**Why this constraint matters:**
- **Principle of Least Privilege**: Prevents overly permissive firewall rules that expose resources to the entire internet
- **Reduces Attack Surface**: Limits exposure by requiring specific IP ranges instead of allowing all traffic
- **Prevents Misconfigurations**: Catches accidental use of 0.0.0.0/0 which is a common security mistake
- **Compliance**: Many security frameworks (CIS, PCI-DSS, SOC2) require restricted network access
- **Defense in Depth**: Adds an additional layer of protection against unauthorized access

Allowing 0.0.0.0/0 in firewall rules means anyone on the internet can attempt to connect to your resources, significantly increasing security risk.

## How It Works

This constraint uses a CEL (Common Expression Language) expression to check if `0.0.0.0/0` appears in either `sourceRanges` or `destinationRanges` of a firewall rule.

**Technical Details:**
- **Resource Type**: `compute.googleapis.com/Firewall`
- **Action Type**: `DENY` (blocks rules with 0.0.0.0/0)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `(has(resource.sourceRanges) && "0.0.0.0/0" in resource.sourceRanges) || (has(resource.destinationRanges) && "0.0.0.0/0" in resource.destinationRanges)`

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_firewall_no_public_access_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_firewall_no_public_access_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for firewall no public access |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a VPC firewall rule with 0.0.0.0/0 as source or destination. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create a firewall rule with 0.0.0.0/0 source range
gcloud compute firewall-rules create test-rule-public-access \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0
```

**Expected error:**
```
ERROR: (gcloud.compute.firewall-rules.create) Could not fetch resource:
 - Constraint custom.computeFirewallNoPublicAccessXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create a firewall rule with specific IP ranges
gcloud compute firewall-rules create test-rule-specific-access \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=10.0.0.0/8,192.168.0.0/16
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_compute_firewall.compliant_specific_range_rule
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_compute_firewall.violating_public_access_rule
   ```

## Notes

- This constraint blocks both ingress rules with `0.0.0.0/0` in `sourceRanges` and egress rules with `0.0.0.0/0` in `destinationRanges`
- You must specify explicit IP ranges or CIDR blocks instead (e.g., `10.0.0.0/8`, `192.168.1.0/24`)
- For legitimate public-facing services, use Cloud Load Balancer with Cloud Armor instead of direct firewall rules
- Consider using Identity-Aware Proxy (IAP) for administrative access instead of opening SSH/RDP to 0.0.0.0/0
- This is one of the most important security constraints to prevent accidental internet exposure
