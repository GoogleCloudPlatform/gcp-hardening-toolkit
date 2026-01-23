# Enforce SSL/TLS for Cloud SQL Instances

This module creates a custom organization policy constraint that ensures all Cloud SQL instances are configured to allow only connections encrypted with SSL/TLS.

## Security Rationale

**Why this constraint matters:**
- **Data in Transit Encryption**: Ensures all database connections are encrypted, protecting sensitive data from interception.
- **Compliance**: Meets requirements for PCI-DSS, HIPAA, and other standards that mandate encryption for data in transit.
- **Consistent Enforcement**: Prevents accidental or intentional creation of instances that allow unencrypted connections.

## How It Works

The constraint uses `DENY` logic to block Cloud SQL instances where `sslMode` is specifically set to `ALLOW_UNENCRYPTED_AND_ENCRYPTED`.

**Technical Details:**
- **Resource Type**: `sqladmin.googleapis.com/Instance`
- **Action Type**: `DENY`
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.settings.ipConfiguration.sslMode in ['ENCRYPTED_ONLY', 'TRUSTED_CLIENT_CERTIFICATE_REQUIRED'] == false`

## Usage

This module is called automatically by the root `main.tf` when the following variable is enabled:

```hcl
enable_sql_ssl_enforcement_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint |
| `policy_name` | The name of the organization policy |

## Validation

### Test with gcloud (should FAIL):

Try creating an instance that allows unencrypted connections:

```bash
gcloud sql instances create violating-instance \
    --project=YOUR_PROJECT_ID \
    --tier=db-f1-micro \
    --region=us-central1 \
    --ssl-mode=ALLOW_UNENCRYPTED_AND_ENCRYPTED
```

**Expected error:**
```
ERROR: (gcloud.sql.instances.create) Precondition check failed.
- Constraint custom.sqlSslEnforcementXXXX violated
```

### Terraform-based Testing

1. **Compliant Test**:
   ```bash
   cd tests/compliant
   terraform apply -target=google_sql_database_instance.compliant_sql_instance
   ```

2. **Non-Compliant Test**:
   ```bash
   cd tests/non-compliant
   terraform apply -target=google_sql_database_instance.violating_sql_instance
   ```
