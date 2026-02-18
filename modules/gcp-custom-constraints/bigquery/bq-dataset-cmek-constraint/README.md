# Enforce BigQuery Dataset Default CMEK Constraint

This module creates a custom organization policy constraint that ensures all BigQuery datasets have a default Customer-Managed Encryption Key (CMEK) configured for new tables.

## Security Rationale

**Why this constraint matters:**
- **Default Protection**: Ensures all new tables in a dataset inherit CMEK encryption automatically
- **Compliance**: Required for regulations like HIPAA, PCI-DSS, and FedRAMP that mandate customer-controlled encryption
- **Operational Efficiency**: Eliminates the need to specify encryption for each individual table
- **Data Sovereignty**: Maintain full control over encryption keys at the dataset level
- **Key Management**: Centralized encryption key management for all tables within a dataset
- **Audit Trail**: Comprehensive logging of all key usage through Cloud KMS audit logs

Without default CMEK at the dataset level, individual tables may be created without proper encryption, creating compliance gaps.

## How It Works

This constraint uses a CEL expression to verify that BigQuery datasets have a default CMEK encryption configuration.

**Technical Details:**
- **Resource Type**: `bigquery.googleapis.com/Dataset`
- **Action Type**: `ALLOW` (only allows compliant resources)
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `has(resource.defaultEncryptionConfiguration) && resource.defaultEncryptionConfiguration.kmsKeyName.startsWith("projects/")`

The constraint checks that:
1. The `defaultEncryptionConfiguration` field exists on the dataset
2. The `kmsKeyName` field contains a valid Cloud KMS key resource path

## Usage

> **Note**: This is an internal module called automatically by the root `main.tf`
> based on the `enable_bigquery_dataset_cmek_constraint` variable in `terraform.tfvars`.
> You do not need to call this module directly.

This module is invoked when you set the corresponding variable to `true` in the root module's `terraform.tfvars` file:

```hcl
enable_bigquery_dataset_cmek_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint for BigQuery dataset CMEK |
| `policy_name` | The name of the organization policy enforcing this constraint |

## Validation

To validate that the custom constraint is working, try to create a BigQuery dataset without default CMEK encryption. The operation should fail with a constraint violation error.

### Test with bq CLI (should FAIL):

```bash
# Try to create dataset without default CMEK
bq mk --dataset \
  --project_id=YOUR_PROJECT_ID \
  --location=us-central1 \
  test_dataset
```

**Expected error:**
```
Error in create operation: Constraint custom.bqDatasetCMEKXXXX violated
```

### Test with bq CLI (should SUCCEED):

```bash
# Create dataset with default CMEK encryption
bq mk --dataset \
  --project_id=YOUR_PROJECT_ID \
  --location=us-central1 \
  --default_kms_key=projects/PROJECT_ID/locations/LOCATION/keyRings/KEY_RING/cryptoKeys/KEY_NAME \
  test_dataset
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test** (Verifies creation is allowed):
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_bigquery_dataset.compliant_dataset
   ```

2. **Non-Compliant Test** (Verifies creation is blocked):
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_bigquery_dataset.violating_bq_dataset
   ```
