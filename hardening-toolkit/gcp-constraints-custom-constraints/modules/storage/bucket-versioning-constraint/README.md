# Enforce Bucket Versioning Constraint

This module creates a custom organization policy constraint that ensures all Cloud Storage buckets have object versioning enabled.

## Security Rationale

**Why this constraint matters:**
- **Data Recovery**: Protects against accidental deletion or overwriting of objects
- **Compliance**: Required for many regulatory frameworks (SOC2, HIPAA, FINRA)
- **Audit Trail**: Maintains history of all object changes for forensic analysis
- **Ransomware Protection**: Allows recovery of files before encryption by malware
- **Insider Threat Mitigation**: Prevents malicious deletion from being permanent

Without versioning, deleted or overwritten data is permanently lost, creating significant business risk.

## How It Works

This constraint uses a CEL expression to verify that the `versioning.enabled` field is set to `true` on all buckets.

**Technical Details:**
- **Resource Type**: `storage.googleapis.com/Bucket`
- **Action Type**: `ALLOW` (only allows compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.versioning.enabled == true`

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_storage_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_storage_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for bucket versioning |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a bucket without versioning enabled. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create bucket without versioning
gcloud storage buckets create gs://test-bucket-no-versioning-$(date +%s) \
  --location=us-central1
```

**Expected error:**
```
ERROR: (gcloud.storage.buckets.create) HTTPError 412: Constraint custom.storageBucketVersioningXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create bucket with versioning enabled
gcloud storage buckets create gs://test-bucket-with-versioning-$(date +%s) \
  --location=us-central1 \
  --versioning
```

### Test with Terraform (should FAIL):

```hcl
resource "google_storage_bucket" "test_no_versioning" {
  name     = "test-bucket-no-versioning"
  location = "US"
  # Missing: versioning { enabled = true }
}
```

### Terraform-based Testing

For complete Terraform validation examples, see the test cases in:
```
../../tests/storage/bucket-versioning-constraint/
```

These tests include both compliant and non-compliant bucket configurations.

## Notes

- Versioning incurs additional storage costs as old versions are retained
- Use lifecycle policies to automatically delete old versions after a retention period
- Versioning can be suspended but not disabled once enabled
- Consider object lifecycle management to control costs
