# GCP SOC2 Compliance Module

This Terraform module automates the deployment of SOC2 Trust Services Criteria controls across your Google Cloud Platform organization. It provides a rapid path to SOC2 compliance by implementing security, availability, and confidentiality controls through organization policies, audit logging, and monitoring.

## Features

This module implements the following SOC2 Trust Services Criteria:

### Security Controls (Common Criteria CC1-CC9) ✅
- **CC6.1-CC6.2**: IAM access controls and service account restrictions
- **CC6.6**: Privileged access monitoring and public IP restrictions
- **CC7.2**: System monitoring with OS Login and Shielded VMs
- **CC8.1**: Change management through audit logging

### Availability Controls (A1.1-A1.3) ✅
- **A1.1**: Automated backup enforcement for Cloud SQL
- **A1.3**: Resource location restrictions for multi-region deployment

### Confidentiality Controls (C1.1-C1.2) ✅
- **C1.1**: Encryption at rest (CMEK enforcement) and data access prevention
- **C1.2**: Encryption in transit and VPC security controls

### Audit Logging & Monitoring
- Comprehensive audit log collection (ADMIN_READ, DATA_READ, DATA_WRITE)
- 365+ day log retention in Cloud Storage and BigQuery
- Real-time security alerts for policy violations
- Evidence collection for SOC2 audits

## Architecture

```
gcp-compliance-soc2/
├── main.tf                          # Main orchestration
├── variables.tf                     # Input variables
├── outputs.tf                       # Module outputs
├── modules/
│   ├── security-controls/           # CC1-CC9 controls
│   ├── availability-controls/       # A1.1-A1.3 controls
│   ├── confidentiality-controls/    # C1.1-C1.2 controls
│   ├── audit-logging/               # Centralized logging
│   └── monitoring-alerting/         # Security alerts
├── examples/
│   ├── basic/                       # Simple deployment
│   └── complete/                    # Full-featured deployment
└── docs/
    └── soc2-control-mapping.md      # Control documentation
```

## Prerequisites

### Required GCP APIs
Enable the following APIs in your quota project:
```bash
gcloud services enable cloudresourcemanager.googleapis.com --project <YOUR_QUOTA_PROJECT>
gcloud services enable orgpolicy.googleapis.com --project <YOUR_QUOTA_PROJECT>
gcloud services enable logging.googleapis.com --project <YOUR_QUOTA_PROJECT>
gcloud services enable monitoring.googleapis.com --project <YOUR_QUOTA_PROJECT>
gcloud services enable bigquery.googleapis.com --project <YOUR_QUOTA_PROJECT>
gcloud services enable storage.googleapis.com --project <YOUR_QUOTA_PROJECT>
```

### Required Permissions
The user or service account deploying this module needs:

**Organization Level:**
- `roles/resourcemanager.organizationAdmin`
- `roles/orgpolicy.policyAdmin`
- `roles/logging.configWriter`

**Project Level (audit project):**
- `roles/owner` or the following roles:
  - `roles/storage.admin`
  - `roles/bigquery.admin`
  - `roles/logging.configWriter`
  - `roles/monitoring.notificationChannelEditor`
  - `roles/monitoring.alertPolicyEditor`

## Usage

### Basic Example

```hcl
module "soc2_compliance" {
  source = "./gcp-compliance-soc2"

  organization_id = "123456789012"
  quota_project   = "my-quota-project"
  audit_project_id = "my-audit-project"
  
  security_team_email = "security@example.com"
  
  enabled_criteria = {
    security        = true
    availability    = true
    confidentiality = true
  }
}
```

### Complete Example

```hcl
module "soc2_compliance" {
  source = "./gcp-compliance-soc2"

  organization_id      = "123456789012"
  folder_id            = "987654321"  # Optional: scope to folder
  quota_project        = "my-quota-project"
  audit_project_id     = "my-audit-project"
  log_bucket_location  = "us-central1"
  
  # Retain logs for 2 years
  audit_log_retention_days = 730
  
  # Enable all criteria
  enabled_criteria = {
    security        = true
    availability    = true
    confidentiality = true
  }
  
  # Restrict resources to specific regions
  allowed_regions = [
    "us-central1",
    "us-east1"
  ]
  
  # Exempt development projects from certain policies
  exempted_projects = [
    "dev-sandbox-123",
    "testing-456"
  ]
  
  # Notification channels
  security_team_email   = "security@example.com"
  compliance_team_email = "compliance@example.com"
  ops_team_email        = "ops@example.com"
}
```

## Configuration

### Required Variables

| Variable | Description | Type |
|----------|-------------|------|
| `organization_id` | GCP Organization ID | string |
| `quota_project` | Project for quota and billing | string |
| `audit_project_id` | Project for audit logs and monitoring | string |
| `security_team_email` | Email for security notifications | string |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `folder_id` | Folder ID for scoped deployment | null (org-level) |
| `log_bucket_location` | Location for audit log storage | "us-central1" |
| `audit_log_retention_days` | Log retention period | 365 |
| `allowed_regions` | Allowed GCP regions | ["us-central1", "us-east1"] |
| `exempted_projects` | Projects exempt from policies | [] |

## Deployment Steps

### Step 1: Configure Variables

Create a `terraform.tfvars` file:

```hcl
organization_id      = "123456789012"
quota_project        = "my-quota-project"
audit_project_id     = "my-audit-project"
security_team_email  = "security@example.com"
```

### Step 2: Initialize Terraform

```bash
cd gcp-compliance-soc2
terraform init
```

### Step 3: Review Plan

```bash
terraform plan
```

### Step 4: Apply Configuration

```bash
terraform apply
```

## Organization Policies Deployed

### Security Controls
- `iam.disableServiceAccountKeyCreation` - Blocks service account key creation
- `iam.automaticIamGrantsForDefaultServiceAccounts` - Disables default SA grants
- `iam.allowedPolicyMemberDomains` - Restricts IAM policy member domains
- `compute.vmExternalIpAccess` - Blocks public IPs on VMs
- `compute.requireOsLogin` - Requires OS Login for SSH
- `compute.requireShieldedVm` - Requires Shielded VMs
- `sql.restrictPublicIp` - Blocks public IPs on Cloud SQL

### Availability Controls
- `gcp.resourceLocations` - Restricts resource locations
- `sql.restrictAuthorizedNetworks` - Enforces SQL backups

### Confidentiality Controls
- `storage.uniformBucketLevelAccess` - Enforces uniform bucket access
- `storage.publicAccessPrevention` - Prevents public bucket access
- `gcp.restrictNonCmekServices` - Requires CMEK encryption
- `compute.restrictVpcPeering` - Restricts VPC peering
- `bigquery.restrictPublicDataset` - Prevents public datasets

## Security Alerts

The module creates the following real-time alerts:

1. **Privileged Role Grants** - Alerts when Owner/Editor roles are granted
2. **Service Account Key Creation** - Alerts on SA key creation attempts
3. **Cloud Storage IAM Changes** - Alerts on GCS permission modifications
4. **Organization Policy Changes** - Alerts on policy modifications

## Audit Evidence Collection

Audit logs are exported to:
- **Cloud Storage**: Long-term retention with lifecycle management
- **BigQuery**: Queryable dataset for evidence collection

Example BigQuery query for privileged access review:
```sql
SELECT
  timestamp,
  protoPayload.authenticationInfo.principalEmail AS user,
  protoPayload.methodName AS action,
  resource.labels.project_id AS project
FROM `<project>.soc2_audit_logs.cloudaudit_googleapis_com_activity_*`
WHERE protoPayload.serviceName = 'iam.googleapis.com'
  AND protoPayload.methodName LIKE '%SetIamPolicy%'
  AND DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAYS)
ORDER BY timestamp DESC;
```

## Outputs

| Output | Description |
|--------|-------------|
| `audit_log_bucket_name` | Cloud Storage bucket for audit logs |
| `audit_log_bigquery_dataset` | BigQuery dataset for log analysis |
| `security_notification_channel_id` | Monitoring channel for security team |
| `enabled_organization_policies` | List of enabled policies |
| `soc2_compliance_summary` | Summary of enabled controls |

## Compliance Notes

### SOC2 Requirements Met
- ✅ Comprehensive audit logging (365+ day retention)
- ✅ Access control enforcement (IAM policies)
- ✅ Encryption at rest and in transit
- ✅ Monitoring and alerting for security events
- ✅ Change management controls
- ✅ Data protection and confidentiality

### Limitations
- This module provides technical controls only
- Organizational policies and procedures must be documented separately
- Regular access reviews and security assessments are still required
- Third-party audit validation is recommended

## Troubleshooting

### Common Issues

**Issue**: Organization policy conflicts
**Solution**: Check for existing policies that may conflict. Use `gcloud org-policies list --organization=<ORG_ID>` to review.

**Issue**: Insufficient permissions
**Solution**: Ensure the deploying account has required roles listed in Prerequisites.

**Issue**: API not enabled
**Solution**: Enable required APIs in the quota project.

## Contributing

Contributions are welcome! Please follow the existing module structure and include:
- Terraform code following Google's style guide
- Documentation updates
- Example usage

## License

See LICENSE file in repository root.

## Support

For issues or questions:
- Review the [SOC2 Control Mapping](docs/soc2-control-mapping.md)
- Check existing GitHub issues
- Contact your security team

## Disclaimer

This module provides a starting point for SOC2 compliance on GCP. It is not a complete compliance solution. Organizations should:
- Review and adapt controls to meet specific requirements
- Conduct regular security assessments
- Engage with qualified auditors for SOC2 certification
- Maintain documentation of policies and procedures
