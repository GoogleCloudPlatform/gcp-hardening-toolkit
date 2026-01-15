# Lumen Service Account Key Management - Implementation Guide

## Overview

This guide provides instructions for implementing the Service Account Key Management solution for the Lumen project, leveraging existing infrastructure and Cloud Asset Inventory automation.

## Prerequisites

- GCP Organization Admin or Security Admin permissions
- `gcloud` CLI installed and configured
- BigPanda integration active (for alerts)
- Access to enable APIs and create Cloud Scheduler jobs

## Implementation Steps

### Phase 1: Verify Existing Infrastructure (Day 1)

**Objective:** Confirm that existing logging and monitoring is functioning correctly and routing to BigPanda.

**Steps:**

1. **Verify Log Sinks & Metrics**
   ```bash
   # Check if log sink exists
   gcloud logging sinks list --project=PROJECT_ID
   
   # Check if log-based metrics exist
   gcloud logging metrics list --project=PROJECT_ID | grep sa_key
   ```

2. **Verify Alert Policies**
   ```bash
   # Check if P1 alert policy exists
   gcloud alpha monitoring policies list \
     --project=PROJECT_ID \
     --filter="displayName:'P1: Service Account Key Created'"
   ```
   
**Expected Outcome:**
- ✅ Log sinks verified
- ✅ Log-based metrics confirmed
- ✅ Alert policies verified active and pointing to BigPanda

---

### Phase 2: Automation Setup (Week 1)

**Objective:** Set up automated detection of policy violations using Cloud Asset Inventory.

**Steps:**

1. **Enable Required APIs**
   ```bash
   gcloud services enable cloudasset.googleapis.com \
     --project=PROJECT_ID
   ```

2. **Run Initial Key Audit**
   ```bash
   cd ../scripts/
   ./audit_sa_keys.sh ORGANIZATION_ID security@lumen.com
   ```

   Review the generated CSV report for:
   - Keys older than 90 days (Rotation Required)
   - Compliance violations

3. **Set Up Automated Weekly Audits**
   ```bash
   ./setup_scheduler.sh PROJECT_ID security@lumen.com
   ```

   *Note: This script deploys a Cloud Function and Cloud Scheduler job to run the audit weekly.*

**Expected Outcome:**
- ✅ Cloud Asset Inventory API enabled
- ✅ Initial audit report generated and emailed
- ✅ Weekly automated audits scheduled via Cloud Scheduler

---

### Phase 3: Integration Testing (Week 1)

**Objective:** Verify end-to-end functionality including alerts and notifications.

**Steps:**

1. **Test Real-Time Alert**
   ```bash
   # Create a test key
   gcloud iam service-accounts keys create test-alert.json \
     --iam-account=test-sa@PROJECT_ID.iam.gserviceaccount.com
     
   # Verify BigPanda alert received within 15 minutes
   
   # Delete test key
   gcloud iam service-accounts keys delete KEY_ID \
     --iam-account=test-sa@PROJECT_ID.iam.gserviceaccount.com
   rm test-alert.json
   ```

2. **Test Weekly Automation**
   ```bash
   # Manually trigger the scheduler job
   gcloud scheduler jobs run sa-key-weekly-audit \
     --project=PROJECT_ID \
     --location=us-central1
   ```

**Expected Outcome:**
- ✅ P1 alert received in BigPanda
- ✅ Weekly audit job runs successfully and sends email

---

### Phase 4: Compliance Remediation (Week 2+)

**Objective:** Maintain 100% compliance through ongoing remediation.

**Steps:**

1. **Review Weekly Audit Reports**
   - Check email inbox for weekly CSV report
   - Identify any keys marked as `ROTATION_REQUIRED`

2. **Remediate Violations**
   - Contact service account owners
   - Rotate keys according to procedure
   - Update dependent applications

3. **Track Progress**
   - Ensure number of non-compliant keys decreases to zero

---

## Verification Checklist

After implementation, verify:

- [ ] Log-based metrics and alerts are active (BigPanda)
- [ ] Cloud Asset Inventory API is enabled
- [ ] Initial audit identified existing compliance gaps
- [ ] Weekly Cloud Scheduler job is active
- [ ] Test key creation triggered P1 alert
- [ ] Test scheduler run sent email notification

---

## Troubleshooting

### Issue: Alerts not appearing in BigPanda

**Solution:**
- Verify GCP alert policy notification channel is configured correctly.
- Check BigPanda integration status in GCP Monitoring console.

### Issue: Audit script shows 'Permission Denied'

**Solution:**
- Ensure the account running the script has `roles/cloudasset.viewer` on the organization.
- For automation, check the service account permissions used by Cloud Scheduler/Function.

### Issue: No email received from audit

**Solution:**
- Check Cloud Function logs for execution errors.
- Verify the email address provided in `setup_scheduler.sh`.

---

## Maintenance

### Weekly Tasks
- Review weekly compliance email
- Investigate any new keys flagged for rotation

### Quarterly Tasks
- Verify Cloud Scheduler job status
- Test alert pipeline with a dummy key

---

## Support

For issues or questions:
- Technical Support: security-engineering@lumen.com
- Security Incidents: soc@lumen.com
- Documentation: See `docs/` directory
