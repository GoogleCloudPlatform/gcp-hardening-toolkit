# SOC2 Control Mapping

This document maps the Terraform resources in this module to specific SOC2 Trust Services Criteria controls.

## Common Criteria (Security) - CC

### CC6.1: Logical and Physical Access Controls

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| Service Account Key Restriction | Cloud IAM | `google_org_policy_policy.disable_sa_key_creation` | Organization Policies |
| Default Service Account Restriction | Cloud IAM | `google_org_policy_policy.disable_default_sa_grants` | Organization Policies |
| Domain Restriction for IAM | Cloud IAM | `google_org_policy_policy.allowed_policy_member_domains` | Organization Policies |
| OS Login Requirement | Compute Engine | `google_org_policy_policy.require_os_login` | Organization Policies |

**Audit Evidence**: 
- Query: IAM policy changes in BigQuery audit logs
- Location: `soc2_audit_logs.cloudaudit_googleapis_com_activity_*`

### CC6.2: Prior to Issuing System Credentials

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| Service Account Key Creation Block | Cloud IAM | `google_org_policy_policy.disable_sa_key_creation` | Organization Policies |

**Audit Evidence**:
- Alert: Service account key creation attempts
- Metric: `soc2-sa-key-creation-attempts`

### CC6.6: Logical and Physical Access Controls - Privileged Access

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| Privileged Role Monitoring | Cloud Logging | `google_logging_metric.privileged_role_grants` | Audit Logs |
| Privileged Role Alerts | Cloud Monitoring | `google_monitoring_alert_policy.privileged_role_grants_alert` | Alert Policies |
| Public IP Restriction | Compute Engine | `google_org_policy_policy.restrict_vm_external_ips` | Organization Policies |
| Cloud SQL Public IP Block | Cloud SQL | `google_org_policy_policy.restrict_sql_public_ip` | Organization Policies |

**Audit Evidence**:
- Alert: Privileged role grants (Owner/Editor)
- Query: Privileged access logs in BigQuery

### CC7.2: System Monitoring

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| Shielded VM Requirement | Compute Engine | `google_org_policy_policy.require_shielded_vm` | Organization Policies |
| Comprehensive Audit Logging | Cloud Logging | `google_organization_iam_audit_config.org_audit_config` | Audit Logs |
| Security Alerts | Cloud Monitoring | Multiple alert policies | Alert History |

**Audit Evidence**:
- All audit logs (ADMIN_READ, DATA_READ, DATA_WRITE)
- Alert notifications sent to security team

### CC8.1: Change Management

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| Organization Policy Change Monitoring | Cloud Logging | `google_logging_metric.org_policy_changes` | Audit Logs |
| Policy Change Alerts | Cloud Monitoring | `google_monitoring_alert_policy.org_policy_changes_alert` | Alert Policies |
| Infrastructure as Code | Terraform | All resources | Version control system |

**Audit Evidence**:
- Alert: Organization policy modifications
- Terraform state and version history

---

## Availability Criteria - A

### A1.1: Availability - Backup and Recovery

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| Cloud SQL Backup Enforcement | Cloud SQL | `google_org_policy_policy.require_sql_backups` | Organization Policies |

**Audit Evidence**:
- Cloud SQL backup logs
- Backup success/failure metrics

### A1.3: Availability - Environmental Protections

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| Resource Location Restriction | Resource Manager | `google_org_policy_policy.restrict_resource_locations` | Organization Policies |

**Audit Evidence**:
- Resource creation logs showing approved regions
- Policy enforcement logs

---

## Confidentiality Criteria - C

### C1.1: Confidentiality - Encryption at Rest

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| CMEK Requirement | Cloud KMS | `google_org_policy_policy.require_cmek` | Organization Policies |
| Uniform Bucket Access | Cloud Storage | `google_org_policy_policy.uniform_bucket_access` | Organization Policies |
| Public Bucket Prevention | Cloud Storage | `google_org_policy_policy.prevent_public_buckets` | Organization Policies |
| Public Dataset Prevention | BigQuery | `google_org_policy_policy.restrict_bigquery_public_datasets` | Organization Policies |

**Audit Evidence**:
- Storage bucket configuration logs
- Encryption key usage logs
- Alert: GCS IAM permission changes

### C1.2: Confidentiality - Encryption in Transit & Network Security

| Control Point | GCP Service | Terraform Resource | Evidence Location |
|--------------|-------------|-------------------|-------------------|
| VPC Peering Restriction | VPC | `google_org_policy_policy.restrict_vpc_peering` | Organization Policies |

**Audit Evidence**:
- VPC configuration logs
- Network traffic logs

---

## Cross-Cutting Controls

### Audit Logging (All Criteria)

| Component | GCP Service | Terraform Resource | Evidence Location |
|-----------|-------------|-------------------|-------------------|
| Organization-Level Audit Logs | Cloud Logging | `google_organization_iam_audit_config.org_audit_config` | Cloud Logging |
| Project-Level Audit Logs | Cloud Logging | `google_project_iam_audit_config.project_audit_config` | Cloud Logging |
| Log Export to Storage | Cloud Storage | `google_logging_organization_sink.audit_logs_export` | Storage Bucket |
| Log Export to BigQuery | BigQuery | `google_logging_organization_sink.audit_logs_bigquery` | BigQuery Dataset |
| Log Retention | Cloud Storage | `google_storage_bucket.audit_logs` (lifecycle rules) | Bucket Configuration |

**Retention Period**: 365+ days (configurable)

**Evidence Collection**:
- Storage bucket: `<org-id>-soc2-audit-logs`
- BigQuery dataset: `soc2_audit_logs`

---

## Evidence Collection Queries

### Privileged Access Review (CC6.6)
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

### Service Account Key Creation Attempts (CC6.2)
```sql
SELECT
  timestamp,
  protoPayload.authenticationInfo.principalEmail AS user,
  protoPayload.resourceName AS service_account,
  severity
FROM `<project>.soc2_audit_logs.cloudaudit_googleapis_com_activity_*`
WHERE protoPayload.serviceName = 'iam.googleapis.com'
  AND protoPayload.methodName = 'google.iam.admin.v1.CreateServiceAccountKey'
  AND DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAYS)
ORDER BY timestamp DESC;
```

### Data Access Logs (C1.1)
```sql
SELECT
  timestamp,
  protoPayload.authenticationInfo.principalEmail AS user,
  protoPayload.resourceName AS resource,
  protoPayload.methodName AS action
FROM `<project>.soc2_audit_logs.cloudaudit_googleapis_com_data_access_*`
WHERE resource.type = 'gcs_bucket'
  AND DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAYS)
ORDER BY timestamp DESC
LIMIT 1000;
```

### Organization Policy Changes (CC8.1)
```sql
SELECT
  timestamp,
  protoPayload.authenticationInfo.principalEmail AS user,
  protoPayload.methodName AS action,
  protoPayload.resourceName AS policy
FROM `<project>.soc2_audit_logs.cloudaudit_googleapis_com_activity_*`
WHERE protoPayload.serviceName = 'orgpolicy.googleapis.com'
  AND DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAYS)
ORDER BY timestamp DESC;
```

---

## Compliance Summary

### Controls Implemented

| Trust Service Category | Controls Implemented | Automated | Manual Review Required |
|------------------------|---------------------|-----------|----------------------|
| Security (CC) | 7 | Yes | Quarterly access reviews |
| Availability (A) | 2 | Yes | Backup testing |
| Confidentiality (C) | 5 | Yes | Encryption key rotation |

### Audit Readiness

- ✅ Comprehensive audit logging enabled
- ✅ 365+ day log retention configured
- ✅ Real-time security alerts active
- ✅ Evidence queries documented
- ✅ Organization policies enforced

### Recommended Additional Controls

1. **Incident Response**: Document and test incident response procedures
2. **Access Reviews**: Conduct quarterly privileged access reviews
3. **Security Training**: Implement security awareness training program
4. **Vulnerability Management**: Regular security scanning and patching
5. **Business Continuity**: Document and test disaster recovery procedures
