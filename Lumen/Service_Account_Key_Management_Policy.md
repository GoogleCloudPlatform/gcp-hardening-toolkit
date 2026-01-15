# Service Account Key Management Policy
## Google Cloud Platform

**Document Version:** 1.0  
**Effective Date:** December 2024  
**Document Owner:** Cloud Security Team  
**Review Cycle:** Annual

---

## Executive Summary

This policy establishes comprehensive governance for Google Cloud Platform (GCP) Service Account key management, ensuring secure credential handling while maintaining operational efficiency. The policy mandates an **"Identity First"** approach where service account keys are treated as an absolute last resort, with Workload Identity Federation as the primary authentication mechanism.

**Key Objectives:**
- Eliminate long-lived credentials through identity federation
- Enforce automated key lifecycle management when keys are unavoidable
- Maintain comprehensive audit trails for compliance and security
- Prevent credential exposure through strict storage and rotation controls

---

## 1. Policy Overview

### 1.1 Purpose

This policy provides mandatory guidance for the creation, storage, rotation, and revocation of GCP Service Account keys. It ensures compliance with organizational cloud security standards while minimizing the attack surface associated with long-lived credentials.

### 1.2 Scope

This policy applies to:
- All GCP Service Accounts across all projects and environments
- All applications and workloads requiring GCP resource access
- Development, staging, and production environments
- Third-party integrations requiring GCP authentication

### 1.3 Policy Statement

**Primary Directive:** Service Account keys shall NOT be created unless Workload Identity Federation or attached Service Accounts are technically impossible.

**Fallback Directive:** When keys must exist, they shall be:
- Generated exclusively through Infrastructure as Code (Terraform)
- Stored only in GCP Secret Manager
- Rotated automatically every 90 days
- Monitored continuously for unauthorized creation or dormancy

---

## 2. Service Account Lifecycle Management

### 2.1 Service Account Creation

#### 2.1.1 Provisioning Requirements

**Mandatory Method:** All Service Accounts MUST be provisioned using Infrastructure as Code (Terraform).

**Rationale:**
- Ensures auditability through version control
- Maintains consistent state management
- Enables automated compliance validation
- Prevents shadow IT and unauthorized accounts

**Prohibited Methods:**
- ❌ Manual creation via GCP Console
- ❌ gcloud CLI commands outside of CI/CD pipelines
- ❌ API calls from developer workstations

#### 2.1.2 Naming Convention

**Standard Format:** `sa-<application>-<service>-<environment>`

**Examples:**
- `sa-payments-api-prod`
- `sa-analytics-etl-staging`
- `sa-monitoring-collector-dev`

**Purpose:**
- Clearly identifies the service account's purpose
- Enables automated policy enforcement
- Facilitates audit and compliance reporting
- Supports cost allocation and resource tracking

**Enforcement:** Implement Terraform validation rules to reject non-compliant names during the provisioning process.

### 2.2 Key Generation & Storage (Fallback Only)

#### 2.2.1 When Keys Are Permitted

Service Account keys may ONLY be created when ALL of the following conditions are met:

1. **Technical Impossibility:** Workload Identity Federation cannot be implemented due to:
   - Legacy on-premises systems without OIDC/SAML support
   - Third-party vendor requirements with no federation capability
   - Documented technical constraints preventing identity federation

2. **Business Justification:** A formal exception request has been approved by:
   - Application Owner
   - Security Team
   - Cloud Architecture Team

3. **Compensating Controls:** Enhanced monitoring and rotation automation are in place

#### 2.2.2 Automated Key Generation

**Mandatory Method:** Keys MUST be generated using Terraform's `google_service_account_key` resource.

**Security Controls:**
- Private key material must never be written to Terraform state (mark as sensitive)
- Key must be transmitted directly from IAM API to Secret Manager API
- No intermediate storage on developer workstations or CI/CD runners
- Base64 encoding should be handled automatically by the provider

#### 2.2.3 Storage Requirements

**Approved Storage Location:** GCP Secret Manager ONLY

**Storage Architecture Flow:**
1. Service Account Key is created via IAM API
2. Terraform Provider receives the key
3. Key is immediately stored in Secret Manager
4. Application retrieves key at runtime from Secret Manager

**Prohibited Storage Locations:**
- ❌ Source code repositories (GitHub, GitLab, Bitbucket)
- ❌ Developer workstations or laptops
- ❌ CI/CD pipeline artifacts
- ❌ Container images or Kubernetes ConfigMaps
- ❌ Email or messaging systems
- ❌ Shared network drives
- ❌ Third-party secret management tools (unless approved exception)

**Secret Manager Configuration Requirements:**
- **Replication:** Automatic (multi-region) for high availability
- **Labels:** Must include `rotation_schedule`, `managed_by`, `owner`
- **IAM:** Least privilege access (only the application service account)
- **Versioning:** Enabled (maintains history for rollback)

### 2.3 Key Rotation

#### 2.3.1 Rotation Frequency

**Mandatory Schedule:** Every 90 days maximum

**Rationale:**
- Limits exposure window if key is compromised
- Aligns with industry best practices (NIST, CIS)
- Meets compliance requirements (SOC2, ISO 27001, PCI-DSS)
- Reduces blast radius of credential leakage

**High-Risk Environments:** Production keys should be rotated every 30 days

#### 2.3.2 Automated Rotation Architecture

**Overview:** Rotation must be fully automated with zero human intervention.

**Architecture Components:**

1. **Secret Manager Rotation Schedule** - Triggers rotation at configured intervals
2. **Cloud Pub/Sub Topic** - Receives rotation events
3. **Cloud Function** - Executes rotation logic:
   - Generate new key via IAM API
   - Add new Secret Manager version
   - Mark old version as disabled
   - Schedule old key deletion
4. **Application** - Fetches new key dynamically without restart

**Key Requirements:**
- Rotation must occur without manual intervention
- Old keys should have a 24-hour grace period before deletion
- Applications must support dynamic credential refresh
- Rotation failures must trigger immediate alerts

#### 2.3.3 Zero-Downtime Requirements

Applications MUST support dynamic credential refresh to enable seamless rotation:

**Application Design Requirements:**
- Implement credential caching with automatic refresh
- Fetch latest secret version from Secret Manager periodically
- Support graceful transition between old and new keys
- Handle credential refresh without application restart

**Recommended Pattern:**
- Cache credentials for 1 hour maximum
- Check for new secret versions before cache expiry
- Implement exponential backoff for Secret Manager API calls
- Log credential refresh events for audit purposes

### 2.4 Key Revocation

#### 2.4.1 Immediate Revocation Triggers

Keys MUST be revoked immediately upon:

1. **Security Incidents:**
   - Suspected or confirmed credential compromise
   - Unauthorized access detected in audit logs
   - Key found in public repositories (GitHub, GitLab)
   - Anomalous usage patterns flagged by Security Command Center

2. **Operational Changes:**
   - Application decommissioning
   - Service account no longer needed
   - Migration to Workload Identity Federation complete

3. **Compliance Requirements:**
   - Employee termination (if they had access)
   - Vendor contract termination
   - Audit finding requiring remediation

#### 2.4.2 Revocation Methods

**Preferred Method:** Remove the key resource from Terraform configuration and apply changes

**Emergency Method:** Use gcloud CLI to delete the key immediately

**Post-Revocation Actions:**
1. Verify key deletion in audit logs
2. Confirm application has switched to new credentials (if rotation)
3. Update incident response documentation
4. Notify stakeholders of revocation

---

## 3. Compliance Framework

### 3.1 Logging Requirements

#### 3.1.1 Audit Log Sources

**Primary Source: Cloud Audit Logs (Admin Activity)**

Admin Activity logs are enabled by default and capture all key lifecycle events:

| Event | Method Name | Information Captured |
|-------|-------------|---------------------|
| Key Creation | `google.iam.admin.v1.CreateServiceAccountKey` | Who created, when, which SA |
| Key Deletion | `google.iam.admin.v1.DeleteServiceAccountKey` | Who deleted, when, which key |
| SA Creation | `google.iam.admin.v1.CreateServiceAccount` | Who created, when, project |
| SA Deletion | `google.iam.admin.v1.DeleteServiceAccount` | Who deleted, when |

**Secondary Source: Data Access Logs (Optional but Recommended)**

Data Access logs show what resources the key accessed:

- **Benefit:** Identifies if compromised key accessed sensitive data
- **Cost:** Higher log volume and storage costs
- **Recommendation:** Enable for production projects only

**Configuration Recommendation:**
Enable Data Access logs for production projects to track:
- DATA_READ operations
- DATA_WRITE operations
- Resource access patterns

#### 3.1.2 Key Usage Indicators

**Recommended Log Filters:**

**Detecting Key Creation:**
- Filter: `resource.type="service_account" AND protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"`
- Purpose: Identify all key creation events

**Detecting Key Authentication:**
- Filter: `protoPayload.authenticationInfo.serviceAccountKeyId!=""`
- Purpose: Track which keys are actively being used

**Detecting Key Deletion:**
- Filter: `resource.type="service_account" AND protoPayload.methodName="google.iam.admin.v1.DeleteServiceAccountKey"`
- Purpose: Audit key revocation events

#### 3.1.3 Log Retention

**Minimum Retention:** 365 days

**Rationale:**
- SOC2 compliance requirement
- Forensic investigation capability
- Trend analysis for security improvements
- Regulatory audit support

**Storage Architecture Recommendations:**
- Use Log Buckets for cost-effective long-term storage
- Export to BigQuery for advanced analytics
- Implement lifecycle policies to transition to cheaper storage tiers
- Maintain separate retention for high-risk projects (2+ years)

### 3.2 Monitoring Requirements

#### 3.2.1 Monitored Events

**1. Unauthorized Key Creation**

**Definition:** Any key created outside approved automation pipelines

**Detection Method:**
- Create log-based metric tracking `CreateServiceAccountKey` events
- Filter to exclude known automation service accounts
- Alert triggers on any manual creation

**Response:** Immediate investigation by security team

**2. Key Age / Rotation Compliance**

**Definition:** Keys exceeding 90-day rotation policy

**Detection Method:**
- Implement weekly scheduled job to query IAM Recommender API
- Identify keys with `validAfterTime` > 90 days ago
- Generate compliance report

**Response:** Automated notification to key owner, escalation if not resolved within 10 days

**3. Dormant Keys**

**Definition:** Keys with `lastAuthenticatedTime` > 90 days

**Detection Method:**
- Use Policy Intelligence Recommender for usage metadata
- Weekly scan identifies unused keys
- Automated revocation after 120 days of inactivity

**Response:** Warning at 90 days, automatic revocation at 120 days

**4. Anomalous Usage (Requires Security Command Center Premium)**

**Definition:** Keys used from unexpected locations or patterns

**Detection Capabilities:**
- Geographic anomalies (key used from unusual country)
- Temporal anomalies (usage outside business hours)
- Volume anomalies (sudden spike in API calls)
- Resource access anomalies (accessing new/sensitive resources)

**Recommendation:** Enable SCC Premium in production projects minimum

#### 3.2.2 Monitoring Implementation Strategy

**Approach 1: Log-Based Metrics (Recommended for All Projects)**

Create custom metrics in Cloud Monitoring that count occurrences of key lifecycle events:
- Track key creation/deletion events
- Monitor key age
- Detect usage patterns
- Generate compliance reports

**Approach 2: Security Command Center (Production Projects)**

Enable Security Health Analytics (SHA) to automatically flag:
- "User-managed service account keys created" as vulnerability finding
- Keys older than rotation threshold
- Dormant keys
- Requires SCC Premium for advanced features

**Approach 3: Custom Scheduled Functions**

Implement Cloud Scheduler-triggered functions to:
- Query IAM Recommender API weekly for key age and usage
- Generate compliance reports
- Send proactive notifications
- Automate remediation for policy violations

### 3.3 Alerting & Notification

#### 3.3.1 Alert Severity Levels

| Severity | Event | Response Time | Notification Channel |
|----------|-------|---------------|---------------------|
| **P1 (Critical)** | Unauthorized key creation | Immediate | Email + PagerDuty + Slack |
| **P2 (High)** | Key rotation failure | 1 hour | Email + Slack |
| **P3 (Medium)** | Key approaching 90-day limit | 24 hours | Email + JIRA ticket |
| **P4 (Low)** | Dormant key detected | 7 days | Email |

#### 3.3.2 Alert Configurations

**P1: Unauthorized Key Creation**

**Trigger:** Manual key creation detected outside automation
**Notification:** PagerDuty, Email, Slack
**Documentation:** Include investigation steps and escalation procedures
**Auto-close:** After 1 hour if resolved

**Actions Required:**
1. Identify who created the key from audit logs
2. Verify if creation was authorized
3. If unauthorized, revoke key immediately
4. Investigate potential compromise
5. Escalate to Cloud Security Team if unable to resolve within 15 minutes

**P2: Key Rotation Failure**

**Trigger:** Automated rotation function fails
**Notification:** Email, Slack
**Documentation:** Include troubleshooting steps
**Auto-close:** After 6 hours if resolved

**Actions Required:**
1. Check Cloud Function logs for errors
2. Verify Secret Manager permissions
3. Manually trigger rotation if needed
4. Update rotation function if bug identified

**P3: Key Rotation Warning**

**Trigger:** Key age exceeds 80 days
**Notification:** Email to service owner, JIRA ticket
**Documentation:** Include rotation instructions
**Auto-close:** After 24 hours

**Actions Required:**
1. Verify automated rotation is configured
2. If manual rotation required, schedule within 10 days
3. Test application compatibility with new key
4. Confirm rotation completes before 90-day deadline

**P4: Dormant Key Alert**

**Trigger:** Key unused for 90+ days
**Notification:** Email to service owner
**Documentation:** Include revocation guidance
**Auto-close:** After 7 days

**Actions Required:**
1. Determine if key is still needed
2. If not needed, revoke immediately
3. If needed, document justification
4. Schedule review in 30 days

#### 3.3.3 Integration with SIEM/SOAR

**Security Command Center to SIEM:**

**Recommendation:** Export SCC findings to Pub/Sub topic, then push to SIEM (Splunk/BigPanda)

**Benefits:**
- Centralized incident management
- Correlation with other security events
- Automated ticket creation
- Integration with existing SOC workflows

**Configuration Requirements:**
- Create Pub/Sub topic for SCC findings
- Configure SCC notification config with filter for key-related findings
- Set up push subscription to SIEM endpoint
- Implement authentication for push endpoint

**Audit Log to BigQuery:**

**Recommendation:** Export audit logs to BigQuery for advanced analytics

**Benefits:**
- SQL-based analysis of key usage patterns
- Long-term trend analysis
- Custom compliance reports
- Integration with BI tools

### 3.4 Alternative Implementation: Wiz Integration

**Overview:** Wiz provides unified cloud security posture management with built-in service account key detection.

**Capabilities:**
- Automatic discovery of all service account keys across GCP projects
- Policy enforcement (flag keys > 90 days old)
- Integration with existing ticketing systems (JIRA, ServiceNow)
- Centralized dashboard for multi-cloud key management

**Limitations:**
- Wiz is not yet formally part of Google Cloud
- Requires separate licensing and deployment
- Limited visibility into Wiz's detection logic (proprietary)

**Recommendation:** Evaluate Wiz as a complementary tool, not a replacement for native GCP monitoring.

**Use Wiz for:**
- Cross-cloud visibility (AWS + Azure + GCP)
- Executive dashboards and reporting
- Integration with existing SOC workflows

**Do NOT rely solely on Wiz for:**
- Real-time alerting (use Cloud Monitoring)
- Automated remediation (use Cloud Functions)
- Audit log retention (use Cloud Logging)

### 3.5 Credential Strategy: Identity First

#### 3.5.1 Google Cloud's Official Guidance

**Direct Quote from Google Cloud Documentation:**

> "We don't recommend using Google Cloud's Secret Manager to store and rotate service account keys."

**Rationale:**

If an application can access Secret Manager, it already has an identity (Workload Identity, Attached Service Account, or Workload Identity Federation). That identity should be used directly to authenticate to GCP resources, eliminating the need for a service account key entirely.

**The Problem with Keys in Secret Manager:**

If the application can authenticate to Secret Manager to fetch a key, it can authenticate to other GCP services using the same identity mechanism. The key becomes an unnecessary security risk.

#### 3.5.2 Primary Recommendation: Workload Identity Federation

**Use Case:** Applications running outside GCP (AWS, Azure, on-premises, CI/CD pipelines)

**How It Works:**

External applications exchange their native credentials (OIDC/SAML tokens) for short-lived GCP access tokens through a Workload Identity Pool that trusts the external identity provider.

**Benefits:**
- ✅ Zero long-lived keys to manage
- ✅ Automatic token expiration (1 hour)
- ✅ No rotation required
- ✅ Audit trail shows external identity
- ✅ Supports AWS, Azure, GitHub Actions, GitLab CI, etc.

**Implementation Steps:**

1. **Create Workload Identity Pool** - Configure trust relationship with external IdP
2. **Create Provider** - Define OIDC/SAML provider details
3. **Configure Attribute Mapping** - Map external identity attributes to GCP
4. **Grant IAM Permissions** - Allow external identity to impersonate service account
5. **Update Application** - Configure to use federation instead of keys

**Supported External Identity Providers:**
- AWS IAM
- Azure Active Directory
- GitHub Actions
- GitLab CI
- Generic OIDC providers
- SAML 2.0 providers

#### 3.5.3 Secondary Recommendation: Attached Service Accounts

**Use Case:** Applications running on GCP compute resources

**Supported Resources:**
- Compute Engine VMs
- Google Kubernetes Engine (GKE) pods
- Cloud Run services
- Cloud Functions
- App Engine

**How It Works:**

The compute resource has a service account attached. Applications running on that resource automatically receive credentials from the metadata server without needing explicit keys.

**Benefits:**
- ✅ GCP manages key rotation automatically
- ✅ No keys to store or distribute
- ✅ Credentials scoped to the compute resource
- ✅ Automatic token refresh

**Implementation Steps:**

1. **Create Service Account** - Define permissions needed
2. **Attach to Compute Resource** - Configure during resource creation
3. **Update Application** - Use Application Default Credentials
4. **Remove Explicit Keys** - Application fetches credentials from metadata server

**Best Practices:**
- Use separate service accounts for different applications
- Follow least privilege principle for IAM permissions
- Enable Workload Identity for GKE (more secure than node service accounts)
- Regularly review and audit attached service account permissions

### 3.6 Fallback Strategy: Legacy Key Management

**IMPORTANT:** This section applies ONLY when Workload Identity Federation is technically impossible.

**Valid Use Cases:**
- Legacy on-premises applications without OIDC/SAML support
- Third-party vendor tools that require JSON key files
- Temporary migration scenarios (with documented sunset plan)

#### 3.6.1 Strict Storage Rules

**Mandatory Requirements:**

1. **Never store keys in source code**
   - No hardcoded credentials in application code
   - No keys in configuration files committed to Git
   - Use `.gitignore` to prevent accidental commits
   - Implement pre-commit hooks to detect keys

2. **Never store keys on developer workstations**
   - No keys in `~/.config/gcloud/`
   - No keys in project directories
   - No keys in browser downloads folder
   - Implement endpoint detection to scan for keys

3. **Use Secret Manager as a Vault**
   - Keys stored as Secret Manager secret versions
   - IAM controls who can access secrets
   - Audit logs track all secret access
   - Automatic encryption at rest

**Why Secret Manager (as a fallback):**

While Google recommends NOT using Secret Manager for keys, it provides critical security controls when keys are unavoidable:

| Security Control | Benefit |
|------------------|---------|
| Audit Trail | `secrets.access` logs show who retrieved keys |
| Access Control | IAM policies limit which SAs can access secrets |
| Encryption | Automatic encryption at rest and in transit |
| Versioning | Maintains history for rollback |
| Rotation | Triggers for automated rotation |

**This is mitigation, not best practice.** The goal is still to eliminate keys entirely.

#### 3.6.2 Automated Rotation Architecture

**Overview:** Fully automated rotation with zero downtime

**Architecture Components:**

1. **Secret Manager Rotation Schedule** - Configured to trigger every 90 days
2. **Pub/Sub Topic** - Receives rotation trigger events
3. **Cloud Function** - Executes rotation logic
4. **Application** - Fetches latest secret version dynamically

**Rotation Workflow:**

1. Secret Manager rotation schedule triggers at configured interval
2. Pub/Sub message sent to rotation topic
3. Cloud Function invoked with rotation event
4. Function generates new key via IAM API
5. New key added as new Secret Manager version
6. Old key marked as disabled (24-hour grace period)
7. Old key deleted after grace period
8. Notification sent to stakeholders

**Key Requirements:**
- Rotation must be fully automated
- No manual intervention required
- 24-hour overlap between old and new keys
- Application must support dynamic credential refresh
- Failures must trigger immediate alerts

#### 3.6.3 Application Integration

**Zero-Downtime Credential Refresh:**

Applications must implement dynamic credential fetching to support seamless rotation:

**Requirements:**
- Fetch credentials from Secret Manager at runtime
- Implement caching to reduce API calls (recommended: 1-hour cache)
- Automatically refresh when cache expires
- Handle credential refresh without application restart
- Implement exponential backoff for Secret Manager API failures

**Recommended Pattern:**
- Create credential provider class/module
- Cache credentials with TTL
- Fetch latest version from Secret Manager when cache expires
- Thread-safe implementation for concurrent requests
- Log credential refresh events for audit

**Benefits:**
- No application restart required during rotation
- Seamless transition between old and new keys
- 24-hour overlap period prevents authentication failures
- Automatic fallback if new key has issues

---

## 4. Roles and Responsibilities

### 4.1 Cloud Security Team

**Responsibilities:**
- Policy enforcement and compliance monitoring
- Security incident response for key compromises
- Review and approve exception requests
- Conduct quarterly access reviews
- Maintain monitoring and alerting infrastructure

**Authority:**
- Revoke keys immediately in security incidents
- Deny exception requests that don't meet criteria
- Escalate policy violations to management

### 4.2 Application Owners

**Responsibilities:**
- Implement Workload Identity Federation where possible
- Request exceptions with proper justification
- Ensure applications support dynamic credential refresh
- Respond to rotation warnings within SLA
- Participate in incident response

**Authority:**
- Approve service account creation for their applications
- Define rotation schedules (within policy limits)
- Request temporary exceptions for migration periods

### 4.3 Platform Engineering Team

**Responsibilities:**
- Maintain rotation automation infrastructure
- Develop and support Terraform modules
- Provide guidance on Workload Identity implementation
- Monitor automation health
- Implement improvements to rotation process

**Authority:**
- Deploy updates to rotation functions
- Modify monitoring thresholds (with security approval)
- Grant access to automation service accounts

### 4.4 Compliance Team

**Responsibilities:**
- Audit adherence to policy
- Generate compliance reports
- Track exception renewals
- Coordinate with external auditors
- Report violations to management

**Authority:**
- Request remediation for policy violations
- Escalate repeated violations
- Recommend policy updates

### 4.5 Security Operations Center (SOC)

**Responsibilities:**
- Triage alerts from monitoring systems
- Investigate anomalous key usage
- Coordinate incident response
- Maintain runbooks for common scenarios
- Escalate critical incidents

**Authority:**
- Initiate incident response procedures
- Request immediate key revocation
- Engage additional teams as needed

---

## 5. Exceptions and Waivers

### 5.1 Exception Request Process

Exceptions to this policy require formal approval through the following process:

**Step 1: Written Justification**
- Application Owner submits exception request
- Must include technical justification
- Document why Workload Identity Federation is impossible
- Provide business impact analysis

**Step 2: Technical Assessment**
- Cloud Architecture Team reviews technical feasibility
- Evaluates alternative solutions
- Assesses security implications
- Provides recommendation

**Step 3: Security Approval**
- Cloud Security Team reviews request
- Evaluates compensating controls
- Assesses risk level
- Approves or denies with rationale

**Step 4: Documentation**
- Approved exceptions documented in central registry
- Compensating controls specified
- Review schedule established
- Stakeholders notified

### 5.2 Exception Criteria

Exceptions may be granted only when:

1. **Technical Impossibility:** Workload Identity Federation cannot be implemented
2. **Business Justification:** Clear business need exists
3. **Compensating Controls:** Enhanced monitoring and rotation in place
4. **Temporary Nature:** Migration plan exists to eliminate keys
5. **Risk Acceptance:** Management acknowledges residual risk

### 5.3 Exception Review

**Review Frequency:** Quarterly

**Review Process:**
- Verify exception is still needed
- Confirm compensating controls are effective
- Check progress on migration plan
- Renew or revoke exception

**Automatic Revocation:**
- Exception expires if not renewed within 30 days
- Keys must be revoked unless exception renewed
- Application Owner notified 60 days before expiration

---

## 6. Policy Review and Updates

### 6.1 Review Schedule

**Regular Review:** Annual

**Trigger Events for Ad-Hoc Review:**
- Security incidents involving service account keys
- Technology changes (new GCP features)
- Compliance requirement updates
- Audit findings
- Industry best practice changes

### 6.2 Update Process

1. **Proposal:** Security Team proposes policy updates
2. **Review:** Stakeholder review and feedback
3. **Approval:** CISO approval required
4. **Communication:** Policy changes communicated to all teams
5. **Training:** Updated training materials provided
6. **Implementation:** Grace period for compliance (typically 90 days)

### 6.3 Version Control

- All policy versions maintained in version control
- Change log documents all modifications
- Previous versions archived for reference
- Stakeholders notified of material changes

---

## 7. Compliance and Audit

### 7.1 Compliance Metrics

**Key Performance Indicators:**

| Metric | Target | Measurement Frequency |
|--------|--------|----------------------|
| % of keys rotated within 90 days | 100% | Weekly |
| % of new keys created via automation | 100% | Daily |
| Mean time to revoke compromised key | < 1 hour | Per incident |
| % of applications using Workload Identity | > 80% | Monthly |
| Dormant keys detected and revoked | 100% | Weekly |

### 7.2 Audit Requirements

**Internal Audits:** Quarterly

**Audit Scope:**
- Review all service account keys
- Verify rotation compliance
- Check exception approvals
- Validate monitoring effectiveness
- Test incident response procedures

**External Audits:** Annual (or per compliance requirement)

**Audit Evidence:**
- Audit logs showing key lifecycle events
- Compliance reports
- Exception documentation
- Incident response records
- Training completion records

### 7.3 Reporting

**Monthly Reports:**
- Key creation/deletion statistics
- Rotation compliance status
- Exception status
- Policy violations

**Quarterly Reports:**
- Trend analysis
- Workload Identity adoption progress
- Security incidents summary
- Recommendations for improvement

**Annual Reports:**
- Comprehensive policy effectiveness review
- Comparison to industry benchmarks
- Strategic recommendations
- Budget requirements for improvements

---

## Appendix A: Quick Reference

### A.1 Decision Tree: Which Authentication Method?

**Question 1:** Is application running on GCP?
- **YES** → Use Attached Service Account
- **NO** → Go to Question 2

**Question 2:** Does external system support OIDC/SAML?
- **YES** → Use Workload Identity Federation
- **NO** → Request exception for Service Account Key

**If exception approved:**
- Use automated rotation (90-day maximum)
- Store in Secret Manager only
- Implement enhanced monitoring

### A.2 Common Scenarios

**Scenario 1: New Application on GCP**
- **Solution:** Attach service account to compute resource
- **No keys needed**

**Scenario 2: GitHub Actions Deployment**
- **Solution:** Workload Identity Federation with GitHub OIDC
- **No keys needed**

**Scenario 3: AWS Lambda accessing GCP**
- **Solution:** Workload Identity Federation with AWS IAM
- **No keys needed**

**Scenario 4: Legacy On-Prem Application**
- **Solution:** Request exception, use automated rotation
- **Keys required (fallback only)**

### A.3 Key Commands Reference

**List all service accounts in project:**
```
gcloud iam service-accounts list --project=PROJECT_ID
```

**List all keys for a service account:**
```
gcloud iam service-accounts keys list --iam-account=SA_EMAIL
```

**Check key age:**
```
gcloud iam service-accounts keys list --iam-account=SA_EMAIL --format="table(name,validAfterTime)"
```

**Delete a specific key:**
```
gcloud iam service-accounts keys delete KEY_ID --iam-account=SA_EMAIL
```

**Describe organization policies:**
```
gcloud org-policies describe CONSTRAINT_NAME --organization=ORG_ID
```

### A.4 Useful Log Queries

**Find all key creation events in last 30 days:**
```
resource.type="service_account"
protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
timestamp>="2024-11-11T00:00:00Z"
```

**Find keys created by specific user:**
```
resource.type="service_account"
protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
protoPayload.authenticationInfo.principalEmail="user@example.com"
```

**Find all key deletions:**
```
resource.type="service_account"
protoPayload.methodName="google.iam.admin.v1.DeleteServiceAccountKey"
```

### A.5 Escalation Contacts

| Issue Type | Contact | Response Time |
|------------|---------|---------------|
| Security Incident | SOC Team | Immediate |
| Policy Exception | Cloud Security Team | 2 business days |
| Technical Support | Platform Engineering | 4 hours |
| Compliance Question | Compliance Team | 1 business day |

---

## Appendix B: Glossary

**Service Account:** A special type of Google account that represents an application or compute workload rather than an individual user.

**Service Account Key:** A cryptographic key pair used to authenticate as a service account. Consists of a private key (kept secret) and public key (stored by Google).

**Workload Identity Federation:** A mechanism that allows external workloads to access Google Cloud resources without using service account keys by exchanging external credentials for short-lived access tokens.

**Attached Service Account:** A service account associated with a GCP compute resource (VM, Cloud Run, etc.) that provides automatic credential management.

**OIDC (OpenID Connect):** An identity layer on top of OAuth 2.0 that allows verification of user identity based on authentication performed by an authorization server.

**SAML (Security Assertion Markup Language):** An XML-based standard for exchanging authentication and authorization data between identity providers and service providers.

**Secret Manager:** A Google Cloud service for storing, managing, and accessing secrets such as API keys, passwords, and certificates.

**IAM (Identity and Access Management):** Google Cloud's system for managing access control by defining who (identity) has what access (role) to which resource.

**Audit Logs:** Records of actions taken in Google Cloud, used for security analysis, resource change tracking, and compliance auditing.

**Rotation:** The process of replacing an old cryptographic key with a new one while maintaining service availability.

**Dormant Key:** A service account key that has not been used for authentication within a specified period (typically 90 days).

---

## Appendix C: Related Policies and Standards

### C.1 Internal Policies

- Cloud Security Baseline Policy
- Identity and Access Management Policy
- Incident Response Policy
- Change Management Policy
- Data Classification Policy

### C.2 External Standards

**NIST (National Institute of Standards and Technology):**
- NIST SP 800-53: Security and Privacy Controls
- NIST SP 800-63B: Digital Identity Guidelines (Authentication)

**CIS (Center for Internet Security):**
- CIS Google Cloud Platform Foundation Benchmark
- CIS Controls v8

**Compliance Frameworks:**
- SOC 2 (Service Organization Control 2)
- ISO 27001 (Information Security Management)
- PCI-DSS (Payment Card Industry Data Security Standard)
- HIPAA (Health Insurance Portability and Accountability Act)

### C.3 Google Cloud Documentation

- [Best practices for managing service account keys](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)
- [Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Service account key management](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)
- [Secret Manager best practices](https://cloud.google.com/secret-manager/docs/best-practices)

---

**Document Control:**
- **Version:** 1.0
- **Last Updated:** December 2024
- **Next Review:** December 2025
- **Classification:** Internal Use Only
- **Document Owner:** Cloud Security Team
- **Approver:** Chief Information Security Officer (CISO)
- **Distribution:** All teams with GCP access

---

**Acknowledgments:**

This policy was developed in collaboration with:
- Cloud Security Team
- Platform Engineering Team
- Compliance Team
- Application Development Teams
- Google Cloud Customer Engineering

**Change Log:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | December 2024 | Cloud Security Team | Initial policy creation |

---

**End of Document**
