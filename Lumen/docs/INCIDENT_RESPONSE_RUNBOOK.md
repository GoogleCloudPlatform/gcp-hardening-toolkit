# Service Account Key Security Incident Response Runbook

## P1 Alert: Unauthorized Service Account Key Created

### Alert Details
- **Severity**: P1 (Critical)
- **SLA**: 15-minute response time
- **Escalation**: Security Operations Center (SOC)

---

## Incident Response Procedure

### Step 1: Initial Triage (0-5 minutes)

**Acknowledge the Alert**
```bash
# Note the alert timestamp and details
ALERT_TIME="[from email]"
SA_EMAIL="[from alert]"
PRINCIPAL_EMAIL="[from alert]"
KEY_ID="[from logs]"
```

**Check Alert Context**
```bash
# View the key creation event
gcloud logging read \
  "resource.type=\"service_account\" \
   AND protoPayload.methodName=\"google.iam.admin.v1.CreateServiceAccountKey\" \
   AND resource.labels.email_id=\"$SA_EMAIL\"" \
  --limit=1 \
  --format=json \
  --project=PROJECT_ID
```

**Key Questions:**
- Who created the key? (`principalEmail`)
- When was it created? (`timestamp`)
- Which service account? (`email_id`)
- Was it created via automation or manually?

---

### Step 2: Authorization Verification (5-10 minutes)

**Check if Key Creation Was Authorized**

1. **Review Change Tickets**
   - Check JIRA/ServiceNow for approved change requests
   - Verify the principal is authorized to create keys

2. **Contact Key Creator**
   ```
   Subject: URGENT: Service Account Key Creation Verification
   
   A service account key was created by your account:
   - Service Account: [SA_EMAIL]
   - Time: [TIMESTAMP]
   - Key ID: [KEY_ID]
   
   Was this authorized? Please respond immediately.
   ```

3. **Check Automation Logs**
   - Verify if created by approved CI/CD pipeline
   - Check Cloud Build/Cloud Deploy logs

**Decision Point:**
- ✅ **Authorized**: Proceed to Step 5 (Documentation)
- ❌ **Unauthorized**: Proceed to Step 3 (Containment)
- ❓ **Unknown**: Proceed to Step 3 (Assume breach)

---

### Step 3: Containment (10-15 minutes)

**IMMEDIATE ACTIONS - Do NOT delay**

**A. Revoke the Key**
```bash
# Delete the unauthorized key
gcloud iam service-accounts keys delete "$KEY_ID" \
  --iam-account="$SA_EMAIL" \
  --project=PROJECT_ID

# Verify deletion
gcloud iam service-accounts keys list \
  --iam-account="$SA_EMAIL" \
  --project=PROJECT_ID
```

**B. Disable the Service Account (if compromised)**
```bash
# Disable the service account
gcloud iam service-accounts disable "$SA_EMAIL" \
  --project=PROJECT_ID

# Verify status
gcloud iam service-accounts describe "$SA_EMAIL" \
  --project=PROJECT_ID
```

**C. Revoke Active Sessions**
```bash
# Force re-authentication for all keys
gcloud iam service-accounts keys list \
  --iam-account="$SA_EMAIL" \
  --project=PROJECT_ID \
  --format="value(name)" | \
while read KEY; do
  echo "Revoking: $KEY"
  gcloud iam service-accounts keys delete "$KEY" \
    --iam-account="$SA_EMAIL" \
    --project=PROJECT_ID \
    --quiet
done
```

---

### Step 4: Investigation (15-30 minutes)

**A. Analyze Access Patterns**
```bash
# Check what the key accessed (if Data Access Logs enabled)
gcloud logging read \
  "protoPayload.authenticationInfo.serviceAccountKeyId=\"$KEY_ID\"" \
  --limit=100 \
  --format=json \
  --project=PROJECT_ID > key_access_log.json

# Analyze accessed resources
cat key_access_log.json | jq -r '.[] | "\(.timestamp) \(.protoPayload.methodName) \(.resource.type)"'
```

**B. Check for Lateral Movement**
```bash
# Look for IAM policy changes
gcloud logging read \
  "protoPayload.methodName=~\"SetIamPolicy\" \
   AND protoPayload.authenticationInfo.serviceAccountKeyId=\"$KEY_ID\"" \
  --limit=50 \
  --format=json \
  --project=PROJECT_ID
```

**C. Identify Compromised Resources**
- List all resources accessed by the key
- Check for data exfiltration (GCS downloads, BigQuery exports)
- Review firewall logs for unusual IP addresses

**D. Determine Blast Radius**
```bash
# Get service account permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SA_EMAIL" \
  --format="table(bindings.role)"
```

---

### Step 5: Documentation (Throughout incident)

**Incident Report Template**

```
INCIDENT REPORT: Unauthorized Service Account Key Creation

Incident ID: INC-[YYYYMMDD]-[###]
Severity: P1
Status: [Open/Contained/Resolved]

TIMELINE:
- [HH:MM] Alert received
- [HH:MM] Initial triage completed
- [HH:MM] Key revoked
- [HH:MM] Service account disabled
- [HH:MM] Investigation completed

DETAILS:
- Service Account: [SA_EMAIL]
- Key ID: [KEY_ID]
- Created By: [PRINCIPAL_EMAIL]
- Created At: [TIMESTAMP]
- Authorization Status: [Authorized/Unauthorized/Unknown]

ACTIONS TAKEN:
1. [Action 1]
2. [Action 2]
...

IMPACT ASSESSMENT:
- Resources Accessed: [List]
- Data Exfiltration: [Yes/No/Unknown]
- Blast Radius: [Scope]

ROOT CAUSE:
[Description of how the unauthorized key was created]

REMEDIATION:
- Immediate: [Actions taken]
- Short-term: [Actions planned]
- Long-term: [Process improvements]

LESSONS LEARNED:
[What went well, what needs improvement]
```

---

### Step 6: Recovery (30-60 minutes)

**A. Create New Keys (if needed)**
```bash
# Create new key with proper rotation date
gcloud iam service-accounts keys create new-key.json \
  --iam-account="$SA_EMAIL" \
  --project=PROJECT_ID

# Document key creation
echo "New key created: $(date)" >> key_rotation_log.txt
```

**B. Re-enable Service Account**
```bash
# Only after confirming no compromise
gcloud iam service-accounts enable "$SA_EMAIL" \
  --project=PROJECT_ID
```

**C. Update Dependent Services**
- Rotate keys in all applications using the service account
- Update CI/CD pipelines
- Notify application owners

---

### Step 7: Post-Incident Review (24-48 hours)

**Schedule Post-Incident Meeting**
- Attendees: Security team, service account owner, management
- Review timeline and actions taken
- Identify process improvements

**Action Items:**
- [ ] Update runbook based on lessons learned
- [ ] Implement additional preventive controls
- [ ] Conduct security awareness training
- [ ] Review and update IAM policies
- [ ] Enhance monitoring and alerting

---

## Escalation Matrix

| Time Elapsed | Action | Contact |
|--------------|--------|---------|
| 0-15 min | SOC investigates | SOC Team |
| 15-30 min | Escalate to Security Manager | [Manager Email] |
| 30-60 min | Escalate to CISO | [CISO Email] |
| 60+ min | Executive notification | [Exec Email] |

---

## Common Scenarios

### Scenario 1: Developer Created Key for Testing
**Status**: Low Risk  
**Action**: Educate developer, delete key, document

### Scenario 2: Automated Pipeline Created Key
**Status**: Expected  
**Action**: Verify pipeline approval, document

### Scenario 3: Unknown Principal Created Key
**Status**: High Risk  
**Action**: Immediate containment, full investigation

### Scenario 4: Key Used from Unusual Location
**Status**: Critical  
**Action**: Assume breach, full incident response

---

## Prevention Checklist

After incident resolution:
- [ ] Review org policy: `iam.disableServiceAccountKeyCreation`
- [ ] Implement Workload Identity where possible
- [ ] Enforce 90-day key rotation
- [ ] Enable Data Access Logs for high-risk SAs
- [ ] Conduct security training for developers
- [ ] Update change management process

---

## Quick Reference Commands

**View Recent Key Creations:**
```bash
gcloud logging read \
  'protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"' \
  --limit=10 \
  --format="table(timestamp,protoPayload.authenticationInfo.principalEmail,resource.labels.email_id)"
```

**List All Keys for SA:**
```bash
gcloud iam service-accounts keys list \
  --iam-account=SA_EMAIL \
  --project=PROJECT_ID
```

**Delete Specific Key:**
```bash
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account=SA_EMAIL \
  --project=PROJECT_ID
```

**Check Key Usage:**
```bash
gcloud logging read \
  "protoPayload.authenticationInfo.serviceAccountKeyId=\"KEY_ID\"" \
  --limit=100
```

---

## Contact Information

- **SOC Hotline**: [Phone Number]
- **Security Team Email**: security@lumen.com
- **On-Call Engineer**: [PagerDuty Link]
- **Incident Management**: [ServiceNow Link]
