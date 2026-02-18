# Enforce Dataproc Cluster CMEK Constraint

This module creates a custom organization policy constraint that ensures all Dataproc clusters use Customer-Managed Encryption Keys (CMEK) for persistent disk encryption.

## Security Rationale

**Why this constraint matters:**
- **Data Protection**: Ensures all data stored on Dataproc cluster persistent disks is encrypted with customer-controlled keys
- **Compliance**: Required for regulations like HIPAA, PCI-DSS, and FedRAMP that mandate customer-controlled encryption
- **Key Rotation**: Enable custom key rotation policies aligned with organizational security requirements
- **Access Control**: Granular control over who can access cluster data through Cloud KMS IAM
- **Audit Trail**: Comprehensive logging of all key usage through Cloud KMS audit logs
- **Data Residency**: Ensure encryption keys remain in specific geographic locations

Without CMEK, Dataproc cluster persistent disks are encrypted with Google-managed keys, which may not meet stringent compliance or data sovereignty requirements.

## How It Works

This constraint uses a CEL expression to verify that Dataproc clusters have CMEK encryption configured for persistent disks.

**Technical Details:**
- **Resource Type**: `dataproc.googleapis.com/Cluster`
- **Action Type**: `ALLOW` (only allows compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `has(resource.config.encryptionConfig) && resource.config.encryptionConfig.gcePdKmsKeyName.startsWith("projects/")`

The constraint checks that:
1. The `encryptionConfig` field exists in the cluster configuration
2. The `gcePdKmsKeyName` field contains a valid Cloud KMS key resource path

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_dataproc_cmek_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_dataproc_cmek_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for Dataproc cluster CMEK |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a Dataproc cluster without CMEK encryption. The operation should fail with a constraint violation error.

### Test with gcloud (should FAIL):

```bash
# Try to create cluster without CMEK
gcloud dataproc clusters create test-cluster \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID
```

**Expected error:**
```
ERROR: (gcloud.dataproc.clusters.create) FAILED_PRECONDITION: Constraint custom.dataprocClusterCMEKXXXX violated
```

### Test with gcloud (should SUCCEED):

```bash
# Create cluster with CMEK encryption
gcloud dataproc clusters create test-cluster \
  --region=us-central1 \
  --project=YOUR_PROJECT_ID \
  --gce-pd-kms-key=projects/PROJECT_ID/locations/LOCATION/keyRings/KEY_RING/cryptoKeys/KEY_NAME
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_dataproc_cluster.compliant_cluster
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_dataproc_cluster.violating_dataproc_cluster
   ```
