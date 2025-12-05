#!/bin/bash

# Set your organization ID and quota project here
ORGANIZATION_ID="YOUR_ORGANIZATION_ID"
QUOTA_PROJECT="YOUR_QUOTA_PROJECT"

# A list of Security Health Analytics modules to enable.
SHA_MODULES=(
  "BUCKET_CMEK_DISABLED"
  "SQL_NO_ROOT_PASSWORD"
  "SQL_WEAK_ROOT_PASSWORD"
  "VPC_FLOW_LOGS_SETTINGS_NOT_RECOMMENDED"
  "ALLOYDB_AUTO_BACKUP_DISABLED"
  "BIGQUERY_TABLE_CMEK_DISABLED"
  "ALLOYDB_CMEK_DISABLED"
  "CLOUD_ASSET_API_DISABLED"
  "DATAPROC_CMEK_DISABLED"
  "DATASET_CMEK_DISABLED"
  "DISK_CMEK_DISABLED"
  "DISK_CSEK_DISABLED"
  "NODEPOOL_BOOT_CMEK_DISABLED"
  "PUBSUB_CMEK_DISABLED"
  "SQL_CMEK_DISABLED"
  "CUSTOM_ORG_POLICY_VIOLATION"
)

for module in "${SHA_MODULES[@]}"; do
  echo "Enabling $module..."
  gcloud alpha scc settings services modules enable \
    --module="$module" \
    --service=SECURITY_HEALTH_ANALYTICS \
    --organization="$ORGANIZATION_ID" \
    --billing-project="$QUOTA_PROJECT"
  echo "$module enabled."
  echo ""
done

echo "All modules enabled."
