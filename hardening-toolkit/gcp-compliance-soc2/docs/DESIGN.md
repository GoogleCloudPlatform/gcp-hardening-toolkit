# SOC2 Compliance Module - Design Document

## Overview

The `gcp-compliance-soc2` Terraform module automates the implementation of SOC2 Trust Services Criteria controls across Google Cloud Platform organizations. It deploys organization policies, audit logging infrastructure, and security monitoring to meet SOC2 compliance requirements.

**Deployment Scope**: Organization `858770860297`  
**Audit Project**: `seed-prj-470417`  
**Total Resources**: 13 organization policies + audit infrastructure + monitoring

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    GCP Organization (858770860297)              │
│                                                                 │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐│
│  │ Security         │  │ Availability     │  │Confidentiality││
│  │ Controls         │  │ Controls         │  │ Controls      ││
│  │ (7 policies)     │  │ (2 policies)     │  │ (4 policies)  ││
│  └──────────────────┘  └──────────────────┘  └───────────────┘│
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Audit Logging (All Services)                │  │
│  │         ADMIN_READ | DATA_READ | DATA_WRITE              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │   Audit Project               │
              │   (seed-prj-470417)           │
              │                               │
              │  ┌─────────────────────────┐  │
              │  │ Cloud Storage Bucket    │  │
              │  │ 858770860297-soc2-      │  │
              │  │ audit-logs              │  │
              │  │ (365-day retention)     │  │
              │  └─────────────────────────┘  │
              │                               │
              │  ┌─────────────────────────┐  │
              │  │ BigQuery Dataset        │  │
              │  │ soc2_audit_logs         │  │
              │  │ (Queryable evidence)    │  │
              │  └─────────────────────────┘  │
              │                               │
              │  ┌─────────────────────────┐  │
              │  │ Monitoring & Alerts     │  │
              │  │ - 4 Alert Policies      │  │
              │  │ - Email Notifications   │  │
              │  └─────────────────────────┘  │
              └───────────────────────────────┘
```

---

## Module 1: Security Controls

**Purpose**: Implements SOC2 Common Criteria (CC1-CC9) security controls  
**Location**: `modules/security-controls/`  
**Policies Deployed**: 7

### Controls Implemented

#### CC6.1 & CC6.2: IAM Access Controls

**Policy**: `iam.disableServiceAccountKeyCreation`
- **What it does**: Blocks creation of service account keys
- **Why**: Service account keys are long-lived credentials that pose security risks. This forces use of short-lived tokens via Workload Identity or service account impersonation.
- **Impact**: Users cannot download JSON keys for service accounts

**Policy**: `iam.automaticIamGrantsForDefaultServiceAccounts`
- **What it does**: Prevents automatic Editor role grants to default service accounts
- **Why**: Default service accounts get Editor role automatically, violating least privilege
- **Impact**: New projects won't have overly permissive default service accounts

**Policy**: `iam.allowedPolicyMemberDomains`
- **What it does**: Restricts which domains can be added to IAM policies
- **Why**: Prevents external accounts from being granted access
- **Impact**: Only specified domains can be added to IAM bindings (currently allows all)

#### CC6.6: Privileged Access Monitoring

**Policy**: `compute.vmExternalIpAccess`
- **What it does**: Blocks VMs from having public IP addresses
- **Why**: Reduces attack surface by preventing direct internet access to VMs
- **Impact**: VMs must use Cloud NAT or IAP for internet/external access

**Policy**: `sql.restrictPublicIp`
- **What it does**: Prevents Cloud SQL instances from having public IPs
- **Why**: Databases should not be directly accessible from the internet
- **Impact**: Cloud SQL instances must use Private IP or Cloud SQL Proxy

#### CC7.2: System Monitoring

**Policy**: `compute.requireOsLogin`
- **What it does**: Requires OS Login for SSH access to VMs
- **Why**: Centralized identity management and audit logging for SSH access
- **Impact**: Users must use `gcloud compute ssh` instead of traditional SSH keys

**Policy**: `compute.requireShieldedVm`
- **What it does**: Requires all VMs to be Shielded VMs
- **Why**: Protects against rootkits and boot-level malware
- **Impact**: All new VMs must have Secure Boot, vTPM, and Integrity Monitoring enabled

### Evidence Collection

- IAM policy changes logged to BigQuery
- Service account key creation attempts trigger alerts
- Privileged role grants (Owner/Editor) trigger critical alerts

---

## Module 2: Availability Controls

**Purpose**: Implements SOC2 Availability Criteria (A1.1-A1.3)  
**Location**: `modules/availability-controls/`  
**Policies Deployed**: 2

### Controls Implemented

#### A1.3: Resource Location Restrictions

**Policy**: `gcp.resourceLocations`
- **What it does**: Restricts resources to specific GCP regions
- **Why**: Ensures resources are deployed in approved geographic locations for availability and compliance
- **Current Setting**: Allows `us-central1` and `us-east1`
- **Impact**: Resources cannot be created in other regions

#### A1.1: Backup Enforcement

**Policy**: `sql.restrictAuthorizedNetworks`
- **What it does**: Enforces network restrictions on Cloud SQL
- **Why**: Ensures Cloud SQL instances have proper network controls and backup configurations
- **Impact**: Cloud SQL instances must have authorized networks configured

### Evidence Collection

- Resource creation logs showing approved regions
- Cloud SQL configuration logs
- Backup success/failure metrics

---

## Module 3: Confidentiality Controls

**Purpose**: Implements SOC2 Confidentiality Criteria (C1.1-C1.2)  
**Location**: `modules/confidentiality-controls/`  
**Policies Deployed**: 4

### Controls Implemented

#### C1.1: Encryption at Rest

**Policy**: `storage.uniformBucketLevelAccess`
- **What it does**: Enforces uniform bucket-level access on Cloud Storage
- **Why**: Simplifies access control and prevents ACL-based access
- **Impact**: Cannot use legacy ACLs on buckets; must use IAM only

**Policy**: `storage.publicAccessPrevention`
- **What it does**: Prevents Cloud Storage buckets from being made public
- **Why**: Protects against accidental data exposure
- **Impact**: Buckets cannot have `allUsers` or `allAuthenticatedUsers` permissions

**Policy**: `gcp.restrictNonCmekServices`
- **What it does**: Requires Customer-Managed Encryption Keys (CMEK) for specified services
- **Why**: Ensures sensitive data is encrypted with customer-controlled keys
- **Current Setting**: Requires CMEK for:
  - `storage.googleapis.com` (Cloud Storage)
  - `bigquery.googleapis.com` (BigQuery)
  - `compute.googleapis.com` (Compute Engine disks)
  - `sqladmin.googleapis.com` (Cloud SQL)
- **Impact**: New resources in these services must specify a CMEK key

#### C1.2: Network Security

**Policy**: `compute.restrictVpcPeering`
- **What it does**: Blocks VPC peering connections
- **Why**: Prevents data exfiltration through VPC peering to external networks
- **Impact**: Cannot create VPC peering connections

### Evidence Collection

- Storage bucket configuration logs
- Encryption key usage logs
- VPC configuration changes
- Alert on Cloud Storage IAM permission changes

---

## Module 4: Audit Logging

**Purpose**: Centralized audit log collection for all SOC2 criteria  
**Location**: `modules/audit-logging/`  
**Resources Created**: 6

### Components

#### Organization-Level Audit Logs

**Resource**: `google_organization_iam_audit_config`
- **What it does**: Enables all audit log types for all services at org level
- **Log Types**:
  - `ADMIN_READ`: Administrative actions (e.g., creating resources)
  - `DATA_READ`: Data access (e.g., reading files)
  - `DATA_WRITE`: Data modifications (e.g., writing to databases)
- **Scope**: Entire organization (858770860297)

#### Project-Level Audit Logs

**Resource**: `google_project_iam_audit_config`
- **What it does**: Enables audit logs for the audit project itself
- **Why**: Ensures logging infrastructure is also audited
- **Project**: seed-prj-470417

#### Cloud Storage Bucket

**Resource**: `google_storage_bucket.audit_logs`
- **Name**: `858770860297-soc2-audit-logs`
- **Location**: us-central1
- **Retention**: 365 days (SOC2 requirement)
- **Features**:
  - Versioning enabled
  - Uniform bucket-level access
  - Lifecycle policy for automatic deletion after retention period

#### BigQuery Dataset

**Resource**: `google_bigquery_dataset.audit_logs`
- **Dataset ID**: `soc2_audit_logs`
- **Location**: us-central1
- **Purpose**: Queryable audit logs for evidence collection
- **Retention**: 365 days

#### Log Sinks

**Storage Sink**: `google_logging_organization_sink.audit_logs_export`
- **Destination**: Cloud Storage bucket
- **Filter**: All Cloud Audit Logs
- **Purpose**: Long-term retention and archival

**BigQuery Sink**: `google_logging_organization_sink.audit_logs_bigquery`
- **Destination**: BigQuery dataset
- **Filter**: All Cloud Audit Logs
- **Purpose**: Real-time querying and analysis
- **Features**: Partitioned tables for efficient queries

### Evidence Collection Queries

**Privileged Access Review** (CC6.6):
```sql
SELECT timestamp, protoPayload.authenticationInfo.principalEmail AS user,
       protoPayload.methodName AS action
FROM `seed-prj-470417.soc2_audit_logs.cloudaudit_googleapis_com_activity_*`
WHERE protoPayload.serviceName = 'iam.googleapis.com'
  AND protoPayload.methodName LIKE '%SetIamPolicy%'
  AND DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAYS)
ORDER BY timestamp DESC;
```

**Service Account Key Creation Attempts** (CC6.2):
```sql
SELECT timestamp, protoPayload.authenticationInfo.principalEmail AS user,
       protoPayload.resourceName AS service_account
FROM `seed-prj-470417.soc2_audit_logs.cloudaudit_googleapis_com_activity_*`
WHERE protoPayload.methodName = 'google.iam.admin.v1.CreateServiceAccountKey'
  AND DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAYS);
```

---

## Module 5: Monitoring & Alerting

**Purpose**: Real-time security monitoring and alerting  
**Location**: `modules/monitoring-alerting/`  
**Resources Created**: 11 (3 notification channels + 4 metrics + 4 alert policies)

### Notification Channels

**Security Team Channel**
- **ID**: `projects/seed-prj-470417/notificationChannels/810869712943683042`
- **Type**: Email
- **Recipient**: yasirhashmi@google.com
- **Purpose**: Receives all security alerts

**Compliance Team Channel** (Optional)
- **Status**: Not configured
- **Purpose**: Compliance-specific notifications

**Ops Team Channel** (Optional)
- **Status**: Not configured
- **Purpose**: Operational alerts

### Alert Policies

#### 1. Privileged Role Grants (CC6.6)

**Metric**: `soc2-privileged-role-grants`
- **Triggers on**: Owner or Editor role grants
- **Severity**: CRITICAL
- **Filter**:
  ```
  protoPayload.serviceName="cloudresourcemanager.googleapis.com"
  AND protoPayload.methodName="SetIamPolicy"
  AND (role="roles/owner" OR role="roles/editor")
  ```
- **Why**: Privileged roles should be granted rarely and reviewed immediately

#### 2. Service Account Key Creation Attempts (CC6.2)

**Metric**: `soc2-sa-key-creation-attempts`
- **Triggers on**: Any service account key creation
- **Severity**: WARNING
- **Filter**:
  ```
  protoPayload.serviceName="iam.googleapis.com"
  AND protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
  ```
- **Why**: Service account keys are blocked by policy; attempts indicate policy bypass or misconfiguration

#### 3. Cloud Storage IAM Changes (C1.1)

**Metric**: `soc2-gcs-iam-changes`
- **Triggers on**: Changes to Cloud Storage bucket IAM permissions
- **Severity**: WARNING
- **Filter**:
  ```
  resource.type="gcs_bucket"
  AND protoPayload.methodName="storage.setIamPermissions"
  ```
- **Why**: Bucket permission changes could lead to data exposure

#### 4. Organization Policy Changes (CC8.1)

**Metric**: `soc2-org-policy-changes`
- **Triggers on**: Modifications or deletions of organization policies
- **Severity**: CRITICAL
- **Filter**:
  ```
  protoPayload.serviceName="orgpolicy.googleapis.com"
  AND (methodName=~"SetOrgPolicy" OR methodName=~"DeleteOrgPolicy")
  ```
- **Why**: Organization policies are critical security controls; changes must be reviewed

### Alert Response

All alerts are sent to: **yasirhashmi@google.com**

**Response Times**:
- CRITICAL alerts: Immediate review required
- WARNING alerts: Review within 24 hours

---

## Deployment Summary

### Resources Created

| Category | Count | Details |
|----------|-------|---------|
| Organization Policies | 13 | 7 security + 2 availability + 4 confidentiality |
| Audit Logging | 6 | 2 audit configs + 1 bucket + 1 dataset + 2 sinks |
| Monitoring | 11 | 3 channels + 4 metrics + 4 alerts |
| **Total** | **30** | **All successfully deployed** |

### Organization Policies Active

```
✅ iam.disableServiceAccountKeyCreation
✅ iam.automaticIamGrantsForDefaultServiceAccounts
✅ iam.allowedPolicyMemberDomains
✅ compute.vmExternalIpAccess
✅ compute.requireOsLogin
✅ compute.requireShieldedVm
✅ sql.restrictPublicIp
✅ gcp.resourceLocations
✅ sql.restrictAuthorizedNetworks
✅ storage.uniformBucketLevelAccess
✅ storage.publicAccessPrevention
✅ gcp.restrictNonCmekServices
✅ compute.restrictVpcPeering
```

### Audit Infrastructure

- **Bucket**: `858770860297-soc2-audit-logs`
- **Dataset**: `soc2_audit_logs`
- **Retention**: 365 days
- **Notification**: yasirhashmi@google.com

---

## Compliance Coverage

### SOC2 Trust Services Criteria

| Criteria | Controls | Status |
|----------|----------|--------|
| **Security (CC)** | 7 policies + monitoring | ✅ Deployed |
| **Availability (A)** | 2 policies | ✅ Deployed |
| **Confidentiality (C)** | 4 policies | ✅ Deployed |
| **Audit Logging** | Comprehensive | ✅ Deployed |
| **Monitoring** | Real-time alerts | ✅ Deployed |

### Evidence Collection

- ✅ 365+ day audit log retention
- ✅ Queryable logs in BigQuery
- ✅ Real-time security alerts
- ✅ Organization policy enforcement
- ✅ Automated evidence queries

---

## Maintenance & Operations

### Regular Tasks

**Weekly**:
- Review security alert notifications
- Check for policy violations in logs

**Monthly**:
- Run evidence collection queries
- Review privileged access grants
- Verify backup configurations

**Quarterly**:
- Conduct access reviews
- Update exempted projects list if needed
- Review and update allowed regions

**Annually**:
- SOC2 audit preparation
- Policy effectiveness review
- Update CMEK requirements

### Monitoring Dashboards

Access monitoring at:
- **Logs Explorer**: https://console.cloud.google.com/logs/query?project=seed-prj-470417
- **Monitoring**: https://console.cloud.google.com/monitoring?project=seed-prj-470417
- **Organization Policies**: https://console.cloud.google.com/iam-admin/orgpolicies?organizationId=858770860297

---

## Troubleshooting

### Common Issues

**Issue**: Policy blocks legitimate use case  
**Solution**: Add project to `exempted_projects` list in `terraform.tfvars`

**Issue**: Need to create resource in different region  
**Solution**: Add region to `allowed_regions` list

**Issue**: Need to use service account keys for legacy system  
**Solution**: Request temporary policy exemption via change management process

### Support

- **Documentation**: See `README.md` and `docs/soc2-control-mapping.md`
- **Logs**: Check BigQuery dataset `soc2_audit_logs`
- **Alerts**: Review email notifications

---

## Future Enhancements

### Recommended Additions

1. **Processing Integrity (PI)** controls
2. **Privacy (P)** controls  
3. **Automated compliance reporting**
4. **Integration with SIEM tools**
5. **Custom compliance dashboards**
6. **Automated remediation workflows**

### Potential Improvements

- Add Terraform drift detection
- Implement policy testing framework
- Create compliance score calculator
- Add integration with Vanta/Drata
- Implement automated evidence collection

---

## References

- **SOC2 Documentation**: `docs/soc2-control-mapping.md`
- **Deployment Guide**: `DEPLOY.md`
- **Troubleshooting**: `TROUBLESHOOTING.md`
- **GCP Organization Policies**: https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints
