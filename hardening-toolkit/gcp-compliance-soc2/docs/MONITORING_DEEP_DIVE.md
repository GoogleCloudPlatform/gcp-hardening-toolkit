# Monitoring & Alerting Module - Deep Dive

## Overview

The monitoring module creates a **real-time security monitoring system** that watches for suspicious activities across your entire GCP organization and sends immediate email alerts when critical events occur.

**Think of it as a security guard** that:
- 👀 Watches all audit logs 24/7
- 🚨 Raises alarms when something suspicious happens
- 📧 Notifies your security team immediately

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│         GCP Organization (All Projects)                     │
│                                                              │
│  User performs action (e.g., grants Owner role)             │
│                    ↓                                         │
│  Cloud Audit Log generated                                  │
└──────────────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│         Log-Based Metric (Filters specific events)          │
│                                                              │
│  Example: "Did someone grant Owner/Editor role?"            │
│           Counter increments if YES                         │
└──────────────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│         Alert Policy (Checks metric value)                  │
│                                                              │
│  Condition: "If counter > 0 in last 5 minutes"              │
│  Action: Trigger alert                                      │
└──────────────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────────────┐
│         Notification Channel                                │
│                                                              │
│  📧 Email to: yasirhashmi@google.com                        │
│  Subject: "CRITICAL: Privileged Role Grant Detected"        │
└──────────────────────────────────────────────────────────────┘
```

---

## Components Breakdown

### 1. Notification Channels (Who Gets Alerted)

**What they are**: Email addresses that receive alerts

**Created Channels**:

```hcl
# Security Team Channel
resource "google_monitoring_notification_channel" "security_team" {
  display_name = "SOC2 Security Team"
  type         = "email"
  labels = {
    email_address = "yasirhashmi@google.com"
  }
}
```

**Purpose**: 
- Primary contact for all security alerts
- Gets notified immediately when suspicious activity is detected

**Optional Channels** (not currently configured):
- `compliance_team` - For compliance-specific alerts
- `ops_team` - For operational alerts

**How it works**:
1. Alert policy triggers
2. Notification sent to this email
3. Email contains alert details and links to investigate

---

### 2. Log-Based Metrics (What to Watch For)

Log-based metrics are **counters** that increment when specific events occur in audit logs.

#### Metric 1: Privileged Role Grants

**Resource**: `google_logging_metric.privileged_role_grants`

**What it watches**:
```
Someone grants Owner or Editor role to a user/service account
```

**Log Filter**:
```
protoPayload.serviceName="cloudresourcemanager.googleapis.com"
AND protoPayload.methodName="SetIamPolicy"
AND (
  protoPayload.request.policy.bindings.role="roles/owner" OR
  protoPayload.request.policy.bindings.role="roles/editor"
)
```

**Translation**:
- Service: Cloud Resource Manager (manages IAM)
- Method: SetIamPolicy (someone changed permissions)
- Role: Owner or Editor (highly privileged roles)

**Why it matters**:
- Owner/Editor roles have full control over resources
- Should be granted rarely and only after approval
- Unauthorized grants could indicate account compromise

**Example scenario**:
```
❌ BAD: Developer grants themselves Editor role on production project
✅ ALERT: Email sent to security team immediately
🔍 INVESTIGATE: Was this authorized? Is the account compromised?
```

---

#### Metric 2: Service Account Key Creation Attempts

**Resource**: `google_logging_metric.sa_key_creation_attempts`

**What it watches**:
```
Someone tries to create a service account key (JSON key file)
```

**Log Filter**:
```
protoPayload.serviceName="iam.googleapis.com"
AND protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
```

**Translation**:
- Service: IAM
- Method: CreateServiceAccountKey (creating a JSON key)

**Why it matters**:
- Your org policy **blocks** service account key creation
- Any attempt means:
  - Someone is trying to bypass the policy
  - Policy might not be working
  - Potential security misconfiguration

**Example scenario**:
```
❌ ATTEMPT: User tries: gcloud iam service-accounts keys create key.json
🚫 BLOCKED: Organization policy denies the action
✅ ALERT: Email sent - "Someone tried to create SA key (blocked by policy)"
🔍 INVESTIGATE: Who tried? Why? Do they need alternative auth method?
```

---

#### Metric 3: Cloud Storage IAM Changes

**Resource**: `google_logging_metric.gcs_iam_changes`

**What it watches**:
```
Someone changes permissions on a Cloud Storage bucket
```

**Log Filter**:
```
resource.type="gcs_bucket"
AND protoPayload.methodName="storage.setIamPermissions"
```

**Translation**:
- Resource: Cloud Storage bucket
- Method: setIamPermissions (changing who can access the bucket)

**Why it matters**:
- Buckets often contain sensitive data
- Permission changes could:
  - Make bucket public (data leak)
  - Grant unauthorized access
  - Remove required access controls

**Example scenario**:
```
❌ CHANGE: User makes bucket public: gsutil iam ch allUsers:objectViewer gs://my-bucket
✅ ALERT: Email sent - "Bucket permissions changed"
🔍 INVESTIGATE: Was this intentional? Is sensitive data exposed?
```

---

#### Metric 4: Organization Policy Changes

**Resource**: `google_logging_metric.org_policy_changes`

**What it watches**:
```
Someone modifies or deletes an organization policy
```

**Log Filter**:
```
protoPayload.serviceName="orgpolicy.googleapis.com"
AND (
  protoPayload.methodName=~"SetOrgPolicy" OR
  protoPayload.methodName=~"DeleteOrgPolicy"
)
```

**Translation**:
- Service: Organization Policy
- Method: SetOrgPolicy or DeleteOrgPolicy (changing security controls)

**Why it matters**:
- Organization policies are your **security guardrails**
- Changes could:
  - Disable critical security controls
  - Allow previously blocked actions
  - Weaken compliance posture

**Example scenario**:
```
❌ CHANGE: Admin disables "Require OS Login" policy
✅ ALERT: Email sent - "CRITICAL: Org policy changed"
🔍 INVESTIGATE: Was this approved? Is there a change ticket?
```

---

### 3. Alert Policies (When to Send Notifications)

Alert policies **monitor the metrics** and trigger notifications when conditions are met.

#### Alert 1: Privileged Role Grants Alert

**Resource**: `google_monitoring_alert_policy.privileged_role_grants`

**Condition**:
```
IF metric "soc2-privileged-role-grants" > 0 
FOR 5 minutes
THEN trigger alert
```

**Translation**:
- If anyone grants Owner/Editor role
- Alert triggers within 5 minutes
- Severity: **CRITICAL**

**Email you'll receive**:
```
Subject: CRITICAL: Privileged Role Grant Detected

Alert: soc2-privileged-role-grants-alert
Severity: CRITICAL
Project: seed-prj-470417

A privileged role (Owner or Editor) was granted in your organization.

Details:
- Metric: soc2-privileged-role-grants
- Current Value: 1
- Threshold: 0

Actions:
1. Review the grant in Cloud Console
2. Verify it was authorized
3. Revoke if unauthorized

View logs: [Link to Logs Explorer]
```

---

#### Alert 2: Service Account Key Creation Alert

**Resource**: `google_monitoring_alert_policy.sa_key_creation_attempts`

**Condition**:
```
IF metric "soc2-sa-key-creation-attempts" > 0
FOR 5 minutes
THEN trigger alert
```

**Severity**: WARNING (not critical because policy blocks it)

**Email you'll receive**:
```
Subject: WARNING: Service Account Key Creation Attempted

Someone attempted to create a service account key.
This action is blocked by organization policy.

Investigate:
- Who attempted this?
- Why do they need a key?
- Can they use Workload Identity instead?
```

---

#### Alert 3: Cloud Storage IAM Changes Alert

**Resource**: `google_monitoring_alert_policy.gcs_iam_changes`

**Condition**:
```
IF metric "soc2-gcs-iam-changes" > 0
FOR 5 minutes
THEN trigger alert
```

**Severity**: WARNING

**Email you'll receive**:
```
Subject: WARNING: Cloud Storage Bucket Permissions Changed

A Cloud Storage bucket's IAM permissions were modified.

Review:
- Which bucket was affected?
- What permissions were changed?
- Is sensitive data at risk?
```

---

#### Alert 4: Organization Policy Changes Alert

**Resource**: `google_monitoring_alert_policy.org_policy_changes`

**Condition**:
```
IF metric "soc2-org-policy-changes" > 0
FOR 5 minutes
THEN trigger alert
```

**Severity**: **CRITICAL**

**Email you'll receive**:
```
Subject: CRITICAL: Organization Policy Modified

An organization policy was changed or deleted.
This affects security controls across your entire organization.

Immediate Actions:
1. Identify which policy was changed
2. Verify change was approved
3. Assess security impact
4. Revert if unauthorized
```

---

## Real-World Example Walkthrough

### Scenario: Unauthorized Owner Role Grant

**Timeline**:

**14:00:00** - Attacker compromises developer account
```bash
# Attacker runs:
gcloud projects add-iam-policy-binding my-project \
  --member="user:attacker@external.com" \
  --role="roles/owner"
```

**14:00:01** - Cloud Audit Log generated
```json
{
  "protoPayload": {
    "serviceName": "cloudresourcemanager.googleapis.com",
    "methodName": "SetIamPolicy",
    "request": {
      "policy": {
        "bindings": [{
          "role": "roles/owner",
          "members": ["user:attacker@external.com"]
        }]
      }
    }
  }
}
```

**14:00:02** - Log-based metric increments
```
Metric: soc2-privileged-role-grants
Value: 0 → 1
```

**14:00:03** - Alert policy evaluates condition
```
Condition: metric > 0 ✅ TRUE
Action: Trigger alert
```

**14:00:05** - Email sent to yasirhashmi@google.com
```
Subject: CRITICAL: Privileged Role Grant Detected
Body: Owner role granted to user:attacker@external.com
```

**14:05:00** - Security team investigates
- Reviews audit logs
- Identifies unauthorized grant
- Revokes Owner role
- Disables compromised account
- Incident contained within 5 minutes!

---

## Configuration Details

### Alert Timing

**Alignment Period**: 300 seconds (5 minutes)
- How often the metric is evaluated
- Balances between:
  - Too fast: Too many alerts (alert fatigue)
  - Too slow: Delayed detection

**Duration**: 0 seconds
- Alert triggers immediately when condition is met
- No waiting period

### Notification Frequency

**Auto Close**: 1800 seconds (30 minutes)
- Alert auto-resolves if condition clears
- Prevents stale alerts

**Notification Rate Limit**: None
- Every occurrence triggers a notification
- Important for security events

---

## Monitoring Dashboard

You can view all metrics and alerts at:

**Metrics Explorer**:
```
https://console.cloud.google.com/monitoring/metrics-explorer?project=seed-prj-470417
```

**Alert Policies**:
```
https://console.cloud.google.com/monitoring/alerting/policies?project=seed-prj-470417
```

**Logs Explorer** (to see what triggered alerts):
```
https://console.cloud.google.com/logs/query?project=seed-prj-470417
```

---

## SOC2 Compliance Mapping

| Alert | SOC2 Criteria | Purpose |
|-------|---------------|---------|
| Privileged Role Grants | CC6.6 | Monitors privileged access changes |
| SA Key Creation | CC6.2 | Detects authentication bypass attempts |
| GCS IAM Changes | C1.1 | Protects confidential data access |
| Org Policy Changes | CC8.1 | Ensures security controls remain active |

---

## Cost

**Monitoring Costs** (very low):
- Log-based metrics: **FREE** (first 50 metrics)
- Alert policies: **FREE** (first 100 policies)
- Email notifications: **FREE**
- Total: **$0/month** ✅

---

## Maintenance

### Weekly Tasks
- Review alert emails
- Investigate any triggered alerts
- Update notification channels if team changes

### Monthly Tasks
- Review alert frequency
- Adjust thresholds if too many false positives
- Test alerts by triggering intentional events

### Testing Alerts

To test if alerts work:

```bash
# Test privileged role grant alert
gcloud projects add-iam-policy-binding seed-prj-470417 \
  --member="user:test@example.com" \
  --role="roles/editor"

# Wait 5 minutes, you should receive an email

# Clean up
gcloud projects remove-iam-policy-binding seed-prj-470417 \
  --member="user:test@example.com" \
  --role="roles/editor"
```

---

## Troubleshooting

### Not Receiving Alerts?

**Check 1**: Verify notification channel
```bash
gcloud alpha monitoring channels list --project=seed-prj-470417
```

**Check 2**: Verify email address
- Go to: https://console.cloud.google.com/monitoring/alerting/notifications?project=seed-prj-470417
- Confirm yasirhashmi@google.com is listed

**Check 3**: Check spam folder
- Alerts might be filtered as spam
- Add `noreply@google.com` to contacts

**Check 4**: Trigger test alert
- Perform action that should trigger alert
- Wait 5-10 minutes
- Check email

### Too Many Alerts?

**Solution 1**: Adjust alignment period
- Increase from 5 minutes to 15 minutes
- Reduces alert frequency

**Solution 2**: Add conditions
- Only alert during business hours
- Only alert for specific projects
- Require multiple occurrences

**Solution 3**: Use notification channels strategically
- CRITICAL alerts → Security team
- WARNING alerts → Ops team
- INFO alerts → Log only, no email

---

## Summary

The monitoring module provides **real-time security monitoring** by:

1. **Watching** audit logs for 4 critical security events
2. **Counting** occurrences using log-based metrics
3. **Alerting** via email when suspicious activity detected
4. **Enabling** rapid incident response (within 5 minutes)

**Key Benefits**:
- ✅ Immediate threat detection
- ✅ Zero cost
- ✅ SOC2 compliance evidence
- ✅ Automated 24/7 monitoring
- ✅ No manual log review needed

**Current Status**:
- 📧 Alerts sent to: yasirhashmi@google.com
- 🚨 4 alert policies active
- 📊 4 log-based metrics monitoring
- ⏱️ 5-minute detection window
