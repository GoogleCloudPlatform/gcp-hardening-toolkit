# Enforce Backend Service Logging Constraint

This module creates a custom organization policy constraint that ensures all Cloud Load Balancer backend services have logging enabled for audit and troubleshooting purposes.

## Security Rationale

**Why this constraint matters:**
- **Audit Trail**: Provides visibility into backend service traffic patterns and access
- **Troubleshooting**: Essential for diagnosing performance issues and errors
- **Security Monitoring**: Enables detection of anomalous traffic patterns
- **Compliance**: Required for many security frameworks (SOC2, PCI-DSS, HIPAA)

Without logging, you have no visibility into backend service behavior, making it impossible to detect attacks or diagnose issues.

## How It Works

This constraint uses a CEL (Common Expression Language) expression to check that the `logConfig.enable` field is set to `true` on all backend services.

**Technical Details:**
- **Resource Type**: `compute.googleapis.com/BackendService`
- **Action Type**: `ALLOW` (only allows compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.logConfig.enable == true`

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_compute_backend_service_logging_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_compute_backend_service_logging_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for backend service logging |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a backend service without logging enabled. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Create a backend service without logging
gcloud compute backend-services create test-backend-no-logging \
  --global \
  --protocol=HTTP \
  --health-checks=default-health-check
```

**Expected error:**
```
ERROR: (gcloud.compute.backend-services.create) Could not fetch resource:
 - Constraint custom.computeBackendServiceLoggingXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create a backend service WITH logging enabled
gcloud compute backend-services create test-backend-with-logging \
  --global \
  --protocol=HTTP \
  --health-checks=default-health-check \
  --enable-logging \
  --logging-sample-rate=1.0
```

### Terraform-based Testing

For Terraform validation examples, see the test cases in:
```
../../tests/compute/backend-service-logging-constraint/
```

These tests include both compliant and non-compliant resource configurations.

## Notes

- Logging can impact performance at very high traffic volumes; consider using sampling rates < 1.0 for high-traffic services
- Logs are stored in Cloud Logging and incur storage costs
- This constraint applies to both global and regional backend services
