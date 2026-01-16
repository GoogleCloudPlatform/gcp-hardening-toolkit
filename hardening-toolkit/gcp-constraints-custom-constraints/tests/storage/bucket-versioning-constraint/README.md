# Storage Bucket Versioning Constraint Test

This Terraform configuration tests the `bucket-versioning-constraint` custom constraint.

## Purpose

This test validates that the organization policy correctly:
- **Allows** creation of Cloud Storage buckets with versioning enabled (compliant)
- **Blocks** creation of Cloud Storage buckets without versioning (non-compliant)

## Prerequisites

> **Important**: Before running this test, ensure the constraint has been deployed.
>
> ```bash
> # From the root gcp-constraints directory
> cd ../../../
> terraform apply
>
> # Return to this test directory
> cd tests/storage/bucket-versioning-constraint/
> ```

## Resources

This test creates two Cloud Storage bucket resources:

1. **`compliant_bucket`**: Compliant bucket with versioning enabled
   - Configuration: `versioning { enabled = true }`
   - Expected: Creation should **succeed**

2. **`violating_bucket`**: Non-compliant bucket with versioning disabled
   - Configuration: `versioning { enabled = false }`
   - Expected: Creation should **fail** with constraint violation

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Configure Project ID

Set your `project_id` variable in a `terraform.tfvars` file or use the `-var` flag:

```bash
echo 'project_id = "your-project-id"' > terraform.tfvars
```

### 3. Test Compliant Resource (should SUCCEED)

```bash
terraform apply -target=google_storage_bucket.compliant_bucket
```

**Expected outcome**: The bucket is created successfully.

### 4. Test Non-Compliant Resource (should FAIL)

```bash
terraform apply -target=google_storage_bucket.violating_bucket
```

**Expected error**:
```
Error: Error creating Bucket: googleapi: Error 412: Precondition not met
Constraint: custom.storageBucketVersioningXXXX violated for projects/PROJECT_ID
```

This failure confirms the constraint is working correctly.

## Cleanup

Remove test resources:

```bash
terraform destroy
```

Or remove specific resources:

```bash
terraform destroy -target=google_storage_bucket.compliant_bucket
```
