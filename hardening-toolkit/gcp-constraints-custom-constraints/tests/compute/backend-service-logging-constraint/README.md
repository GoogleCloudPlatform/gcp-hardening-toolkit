# Backend Service Logging Constraint Test

This Terraform configuration tests the `backend-service-logging-constraint` custom constraint.

## Purpose

This test validates that the organization policy correctly:
- **Allows** creation of backend services with logging enabled (compliant)
- **Blocks** creation of backend services without logging (non-compliant)

## Prerequisites

> **Important**: Before running this test, ensure the constraint has been deployed.
>
> ```bash
> # From the root gcp-constraints directory
> cd ../../../
> terraform apply
>
> # Return to this test directory
> cd tests/compute/backend-service-logging-constraint/
> ```

## Resources

This test creates two backend service resources:

1. **`compliant_service`**: Compliant backend service with logging enabled
   - Configuration: `log_config { enable = true }`
   - Expected: Creation should **succeed**

2. **`violating_service`**: Non-compliant backend service with logging disabled
   - Configuration: `log_config { enable = false }`
   - Expected: Creation should **fail** with constraint violation

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Test Compliant Resource (should SUCCEED)

```bash
terraform apply -target=google_compute_backend_service.compliant_service
```

**Expected outcome**: The backend service is created successfully with logging enabled.

### 3. Test Non-Compliant Resource (should FAIL)

```bash
terraform apply -target=google_compute_backend_service.violating_service
```

**Expected error**:
```
Error: Error creating BackendService: googleapi: Error 412: Precondition not met
Constraint: custom.computeBackendServiceLoggingXXXX violated for projects/PROJECT_ID
```

This failure confirms the constraint is working correctly.

## Cleanup

Remove test resources:

```bash
terraform destroy
```

Or remove specific resources:

```bash
terraform destroy -target=google_compute_backend_service.compliant_service
```
