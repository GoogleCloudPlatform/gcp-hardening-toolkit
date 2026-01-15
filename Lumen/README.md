# Lumen Service Account Key Management

## Solution Overview

Custom notification system for service account key rotation using **Cloud Asset Inventory** (Google's recommended approach).

## What This Solution Provides

### 1. **Automated Key Rotation Detection**
- Uses Cloud Asset Inventory API to find keys >90 days old
- Organization-wide scanning (all projects)
- Efficient querying with `createTime` filter

### 2. **Weekly Rotation Notifications**
- Automated email alerts for keys requiring rotation
- CSV reports with key details and remediation steps
- Cloud Scheduler automation (every Monday 9 AM)

### 3. **Incident Response Integration**
- Works with existing BigPanda alerts for real-time detection
- Complements existing log sinks and metrics
- Provides compliance evidence for audits

## How It Works

**Cloud Asset Inventory Query:**
```bash
gcloud asset search-all-resources \
    --scope="organizations/123456789012" \
    --query="createTime < 2023-03-10" \
    --asset-types="iam.googleapis.com/ServiceAccountKey" \
    --order-by="createTime"
```

**Weekly Automation:**
```
Cloud Scheduler → Audit Script → Cloud Asset Inventory → CSV Report → Email
```

## Quick Start

**Run Manual Audit:**
```bash
cd scripts/
./audit_sa_keys.sh ORGANIZATION_ID security@lumen.com
```

**Set Up Weekly Automation:**
```bash
./setup_scheduler.sh PROJECT_ID security@lumen.com
```

## Integration with Existing Infrastructure

✅ **Already Configured:**
- Log-based metrics for key creation
- P1 alerts to BigPanda
- Log sinks for audit events

✅ **This Solution Adds:**
- Proactive rotation enforcement (weekly scans)
- Organization-wide key inventory
- Automated compliance notifications

## Cost

- Cloud Asset Inventory API: Free
- Cloud Scheduler: <$1/month
- Cloud Function: <$5/month
- **Total: <$10/month**

## Files

- `scripts/audit_sa_keys.sh` - Cloud Asset Inventory-based audit
- `scripts/setup_scheduler.sh` - Weekly automation setup
- `docs/INCIDENT_RESPONSE_RUNBOOK.md` - Response procedures
- `docs/IMPLEMENTATION_GUIDE.md` - Deployment steps

## Next Steps

1. Run initial audit to identify current non-compliant keys
2. Set up weekly automation
3. Review and rotate identified keys
4. Monitor weekly reports for ongoing compliance
