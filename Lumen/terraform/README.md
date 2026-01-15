# Lumen Service Account Key Management - Terraform

## ⚠️ Important Note

**The following infrastructure already exists in the Lumen environment:**
- ✅ Log-based metrics for SA key creation/deletion
- ✅ Alert policies routing to BigPanda
- ✅ Log sinks for audit events

**No Terraform deployment is required.**

## What This Directory Contains

This directory is provided for reference only, showing what infrastructure would typically be needed for a complete SA key management solution.

## Actual Deployment

Since the infrastructure already exists, you only need to deploy:

1. **Audit Script** - Uses Cloud Asset Inventory API
   ```bash
   cd ../scripts/
   ./audit_sa_keys.sh ORGANIZATION_ID security@lumen.com
   ```

2. **Weekly Automation** - Cloud Scheduler for automated audits
   ```bash
   ./setup_scheduler.sh PROJECT_ID security@lumen.com
   ```

## Cost

Since no new infrastructure is deployed:
- Cloud Asset Inventory API: **Free**
- Cloud Scheduler: **<$1/month**
- Cloud Function (for automation): **<$5/month**

**Total: <$10/month**

## Reference Architecture

For reference, a complete SA key management solution would include:

```hcl
# Log Bucket (365-day retention)
resource "google_logging_project_bucket_config" "sa_key_audit_logs" {
  # Already exists in Lumen environment
}

# Log Sink (SA key events)
resource "google_logging_project_sink" "sa_key_events" {
  # Already exists in Lumen environment
}

# Log-Based Metrics
resource "google_logging_metric" "sa_key_creation" {
  # Already exists in Lumen environment
}

# Alert Policy (P1 alerts to BigPanda)
resource "google_monitoring_alert_policy" "sa_key_creation_alert" {
  # Already exists in Lumen environment
}
```

All of these resources are already configured in your environment.
