# GCP SOC2 Compliance Module

This Terraform module automates the deployment of SOC2 Trust Services Criteria controls across your Google Cloud Platform organization. It provides a rapid path to SOC2 compliance by implementing security, availability, and confidentiality controls through organization policies, cost-optimized audit logging, and real-time security monitoring.

## How it works

This module has three main components:

1. **Organization Policies:** Enforces 13 security controls across Security (CC), Availability (A), and Confidentiality (C) criteria through GCP organization policies.

2. **Audit Logging:** Enables comprehensive audit logging (`ADMIN_READ`, `DATA_READ`, `DATA_WRITE`) for all services at the organization level, with cost-optimized Cloud Storage lifecycle policies for 365-day retention.

3. **Security Monitoring:** Creates notification channels and alert policies for real-time detection of:
   - Privileged role grants (Owner/Editor)
   - Service account key creation attempts
   - Cloud Storage IAM permission changes
   - Organization policy modifications

## Disclaimer

This module provides a technical implementation for SOC2 compliance controls on Google Cloud Platform. It is not a complete compliance solution. The configurations are designed to demonstrate how to enforce SOC2 controls and create compliance-related alerts. You should review and adapt the code to meet the specific security and compliance requirements of your organization. Third-party audit validation is recommended for SOC2 certification.

## How to use this module

Here is the recommended workflow to deploy SOC2 compliance controls:

### Prerequisites

* **Google Cloud SDK:** You need to have the `gcloud` command-line tool installed and configured to authenticate to your GCP account.
* **Terraform:** You need to have Terraform installed on your local machine (version 1.0+).
* **Permissions:** The user or service account running Terraform needs the following roles:

  **Organization Level:**
  * `roles/resourcemanager.organizationAdmin`
  * `roles/orgpolicy.policyAdmin`
  * `roles/logging.configWriter`

  **Project Level (audit project):**
  * `roles/owner` or the following roles:
    * `roles/storage.admin`
    * `roles/logging.configWriter`
    * `roles/monitoring.notificationChannelEditor`
    * `roles/monitoring.alertPolicyEditor`

### Step 1: Configure your environment

1. **Enable APIs:** The following APIs must be enabled in the quota project:

   * `cloudresourcemanager.googleapis.com`
   * `orgpolicy.googleapis.com`
   * `logging.googleapis.com`
   * `monitoring.googleapis.com`
   * `storage.googleapis.com`

   You can enable them by running:

   ```bash
   gcloud services enable cloudresourcemanager.googleapis.com --project <YOUR_QUOTA_PROJECT>
   gcloud services enable orgpolicy.googleapis.com --project <YOUR_QUOTA_PROJECT>
   gcloud services enable logging.googleapis.com --project <YOUR_QUOTA_PROJECT>
   gcloud services enable monitoring.googleapis.com --project <YOUR_QUOTA_PROJECT>
   gcloud services enable storage.googleapis.com --project <YOUR_QUOTA_PROJECT>
   ```

2. **Configure Terraform Variables:** Create a `terraform.tfvars` file in the root of the module and add the following variables:

   ```hcl
   organization_id      = "<YOUR_ORGANIZATION_ID>"
   quota_project        = "<YOUR_QUOTA_PROJECT>"
   audit_project_id     = "<YOUR_AUDIT_PROJECT_ID>"
   security_team_email  = "<YOUR_SECURITY_TEAM_EMAIL>"
   ```

### Step 2: Apply the Terraform Configuration

Initialize and apply the Terraform configuration:

```bash
terraform init
terraform apply
```

## What gets deployed

### Organization Policies (13 total)

**Security Controls (7 policies):**
* `iam.disableServiceAccountKeyCreation` - Blocks service account key creation
* `iam.automaticIamGrantsForDefaultServiceAccounts` - Prevents automatic Editor grants
* `iam.allowedPolicyMemberDomains` - Restricts IAM member domains
* `compute.vmExternalIpAccess` - Blocks public IPs on VMs
* `compute.requireOsLogin` - Requires OS Login for SSH access
* `compute.requireShieldedVm` - Requires Shielded VMs
* `sql.restrictPublicIp` - Blocks public IPs on Cloud SQL

**Availability Controls (2 policies):**
* `gcp.resourceLocations` - Restricts resource deployment to approved regions
* `sql.restrictAuthorizedNetworks` - Enforces SQL network restrictions

**Confidentiality Controls (4 policies):**
* `storage.uniformBucketLevelAccess` - Enforces uniform bucket-level access
* `storage.publicAccessPrevention` - Prevents public bucket access
* `gcp.restrictNonCmekServices` - Requires CMEK for sensitive services
* `compute.restrictVpcPeering` - Restricts VPC peering

### Audit Logging Infrastructure

**Cloud Storage Bucket** with cost-optimized lifecycle policies:
* Days 0-30: Standard storage (fast access)
* Days 31-90: Nearline storage (monthly access)
* Days 91-180: Coldline storage (quarterly access)
* Days 181-365: Archive storage (annual compliance)
* Day 365+: Automatic deletion

**Cost Savings:** ~90% reduction vs BigQuery ($24-60/year vs $240-480/year)

### Security Monitoring

**4 Alert Policies** with email notifications:
1. **Privileged Role Grants** (CRITICAL) - Detects Owner/Editor role assignments
2. **Service Account Key Creation** (WARNING) - Alerts on policy bypass attempts
3. **Cloud Storage IAM Changes** (WARNING) - Monitors bucket permission changes
4. **Organization Policy Changes** (CRITICAL) - Alerts on security control modifications

## Configuration Options

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
| `enabled_criteria.security` | Enable security controls | true |
| `enabled_criteria.availability` | Enable availability controls | true |
| `enabled_criteria.confidentiality` | Enable confidentiality controls | true |

## Usage Examples

### Basic Deployment

```hcl
module "soc2_compliance" {
  source = "./gcp-compliance-soc2"

  organization_id      = "123456789012"
  quota_project        = "my-quota-project"
  audit_project_id     = "my-audit-project"
  security_team_email  = "security@example.com"
}
```

### Advanced Deployment

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
  
  # Enable specific criteria
  enabled_criteria = {
    security        = true
    availability    = true
    confidentiality = true
  }
  
  # Restrict to specific regions
  allowed_regions = [
    "us-central1",
    "us-east1"
  ]
  
  # Exempt development projects
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

## Outputs

| Output | Description |
|--------|-------------|
| `audit_log_bucket_name` | Cloud Storage bucket for audit logs |
| `audit_log_bucket_url` | Console URL to access audit log bucket |
| `storage_lifecycle_summary` | Summary of storage lifecycle tiers |
| `security_notification_channel_id` | Monitoring channel for security team |
| `enabled_organization_policies` | List of enabled policies |
| `soc2_compliance_summary` | Summary of enabled controls |

## Audit Evidence Collection

### Accessing Logs

**For recent logs (0-30 days):**
* Use Cloud Logging Logs Explorer (free, real-time)
* Filter and export specific events

**For older logs (30-365 days):**
* Download from Cloud Storage bucket
* Load into BigQuery on-demand for analysis
* Use `gsutil` to search log files

### Example: Load logs into BigQuery for analysis

```bash
# Load specific date range into BigQuery
bq load --source_format=JSON \
  my_dataset.audit_logs \
  gs://ORG_ID-soc2-audit-logs/logs/YYYY/MM/DD/*.json
```

### Example: Query for privileged access review

```sql
SELECT
  timestamp,
  protoPayload.authenticationInfo.principalEmail AS user,
  protoPayload.methodName AS action,
  resource.labels.project_id AS project
FROM `<project>.audit_logs.cloudaudit_googleapis_com_activity_*`
WHERE protoPayload.serviceName = 'iam.googleapis.com'
  AND protoPayload.methodName LIKE '%SetIamPolicy%'
  AND DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAYS)
ORDER BY timestamp DESC;
```

## SOC2 Compliance Coverage

### Trust Services Criteria Implemented

✅ **Security (Common Criteria CC1-CC9)**
* Access controls and authentication
* Logical and physical access restrictions
* System monitoring and change management

✅ **Availability (A1.1-A1.3)**
* Backup and recovery procedures
* Resource location restrictions
* Capacity planning

✅ **Confidentiality (C1.1-C1.2)**
* Encryption at rest and in transit
* Data access prevention
* Network security controls

### Compliance Notes

* Comprehensive audit logging (365-day retention)
* Real-time security monitoring and alerting
* Evidence collection for SOC2 audits
* Automated enforcement of security controls

### Limitations

* This module provides technical controls only
* Organizational policies and procedures must be documented separately
* Regular access reviews and security assessments are still required
* Third-party audit validation is recommended for SOC2 certification

## Troubleshooting

### Common Issues

**Issue:** Organization policy conflicts  
**Solution:** Check for existing policies that may conflict. Use `gcloud org-policies list --organization=<ORG_ID>` to review.

**Issue:** Insufficient permissions  
**Solution:** Ensure the deploying account has required roles listed in Prerequisites.

**Issue:** API not enabled  
**Solution:** Enable required APIs in the quota project using the commands in Step 1.

**Issue:** Cost concerns about audit logging  
**Solution:** This module uses Cloud Storage lifecycle policies for ~90% cost savings vs BigQuery. Logs automatically transition to cheaper storage tiers over time.

## Module Structure

```
gcp-compliance-soc2/
├── main.tf                          # Main orchestration
├── variables.tf                     # Input variables
├── outputs.tf                       # Module outputs
└── modules/
    ├── security-controls/           # CC1-CC9 controls
    ├── availability-controls/       # A1.1-A1.3 controls
    ├── confidentiality-controls/    # C1.1-C1.2 controls
    ├── audit-logging/               # Cost-optimized logging
    └── monitoring-alerting/         # Security alerts
```

## Support

For issues or questions:
* Review the module documentation
* Check existing GitHub issues
* Contact your security team

## License

See LICENSE file in repository root.
