# Storage Bucket Versioning Constraint Test

This Terraform configuration is designed to test the custom constraint that enforces versioning on Google Cloud Storage buckets.

## Purpose

The `main.tf` file defines two `google_storage_bucket` resources:
1.  **`compliant_bucket`**: This bucket has versioning explicitly enabled, making it compliant with the policy.
2.  **`violating_bucket`**: This bucket has versioning disabled, which violates the policy.

The purpose of this setup is to verify that the organization policy correctly allows the creation of compliant buckets while blocking the creation of non-compliant ones.

## How to Use

1.  **Initialize Terraform:**
    ```bash
    terraform init
    ```
2.  **Set your Project ID:**
    You can set the `project_id` variable in a `terraform.tfvars` file or by using the `-var` flag during the apply command.

### Testing the Compliant Resource
To create only the compliant bucket, run:
```bash
terraform apply -target=google_storage_bucket.compliant_bucket
```
**Expected Outcome:** The `apply` command should complete successfully, creating the `compliant-bucket-xxxx` storage bucket.

### Testing the Non-Compliant Resource
To attempt to create the violating bucket, run:
```bash
terraform apply -target=google_storage_bucket.violating_bucket
```
**Expected Outcome:** The `apply` command should fail with a `412 Precondition not met` error. This failure confirms that the constraint is working as intended by preventing the creation of a bucket without versioning enabled.
