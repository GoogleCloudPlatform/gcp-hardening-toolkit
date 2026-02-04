# Enforce Locked Rentention Policy for Cloud Storage Buckets

This module creates a custom organization policy constraint that ensures all Cloud Storage buckets are configured with a retention policy.

## Security Rationale

**Why this constraint matters:**
- **Data Integrity**: Retention policies prevent the deletion or modification of data for a specified period, which is crucial for compliance and legal requirements.
- **WORM Compliance**: Once a retention policy is locked, it cannot be reduced or removed, ensuring Write-Once-Read-Many (WORM) compliance.
- **Protection Against Ransomware**: Prevents malicious actors from deleting or encrypting your data before the retention period expires.

## How It Works

The constraint uses `DENY` logic to block the creation or update of buckets that do not have a retention policy configured.

**Technical Details:**
- **Resource Type**: `storage.googleapis.com/Bucket`
- **Action Type**: `DENY`
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.retentionPolicy == null`

> [!IMPORTANT]
> **Two-Step Locking Process**:
> The Cloud Storage API does not allow creating a bucket with an already-locked retention policy. To achieve a locked policy, you must follow this two-stage process:
> 1. Create the bucket with an **unlocked** retention policy.
> 2. Lock the retention policy separately (e.g., via a second Terraform apply or `gcloud`).

## Usage

This constraint is enabled via the `enable_gcs_locked_retention_constraint` variable in the blueprint.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint |
| `org_policy_name` | The name of the organization policy |
