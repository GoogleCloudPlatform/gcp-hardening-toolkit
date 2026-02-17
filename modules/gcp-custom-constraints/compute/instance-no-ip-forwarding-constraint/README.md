# Prevent IP Forwarding on Compute Engine Instances

This module creates a custom organization policy constraint that prevents IP forwarding from being enabled on Compute Engine instances.

## Security Rationale

**Why this constraint matters:**
- **Network Segmentation**: IP forwarding allows instances to act as routers, potentially bypassing network security controls
- **Lateral Movement**: Attackers can use IP forwarding to pivot between network segments
- **VPN/Proxy Abuse**: Prevents instances from being used as unauthorized VPN endpoints or proxies
- **Traffic Interception**: IP forwarding enables man-in-the-middle attacks within the VPC
- **Compliance**: Many security frameworks require explicit justification for IP forwarding
- **Attack Surface**: Reduces the attack surface by limiting network routing capabilities

IP forwarding should only be enabled for specific use cases like NAT gateways, VPN servers, or load balancers, and should be explicitly approved.

## How It Works

This constraint uses a CEL expression to detect and deny instances with IP forwarding enabled.

**Technical Details:**
- **Resource Type**: `compute.googleapis.com/Instance`
- **Action Type**: `DENY` (denies non-compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.canIpForward == true`

The constraint checks that:
1. The `canIpForward` field is not set to `true`

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_instance_no_ip_forwarding_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_instance_no_ip_forwarding_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint preventing IP forwarding |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a Compute Engine instance with IP forwarding enabled. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create instance with IP forwarding enabled
gcloud compute instances create test-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --can-ip-forward
```

**Expected error:**
```
ERROR: (gcloud.compute.instances.create) FAILED_PRECONDITION: Constraint custom.computeInstanceNoIPForwardingXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create instance without IP forwarding (default)
gcloud compute instances create test-instance \
  --zone=us-central1-a \
  --machine-type=e2-micro
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_compute_instance.compliant_instance
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_compute_instance.violating_instance_ip_forwarding
   ```
