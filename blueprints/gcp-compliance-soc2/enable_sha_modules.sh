#!/bin/bash

# Set your organization ID and quota project here
ORGANIZATION_ID="Your Organization ID"
QUOTA_PROJECT="Your Quota Project"

# A list of built-in Security Health Analytics modules to enable for SOC 2.
# These detectors map to SOC 2 Trust Services Criteria as follows:
#
#   Detector                          SOC 2 Criterion
#   ─────────────────────────────────────────────────
#   CLOUD_ASSET_API_DISABLED          CC6.1 – asset visibility
#   AUDIT_LOGGING_DISABLED            CC6.1, CC6.2 – audit trail
#   KMS_PUBLIC_KEY                    CC6.1, CC6.7 – encryption key exposure
#   PUBLIC_DATASET                    CC6.1, CC6.7 – data access control
#   KMS_KEY_NOT_ROTATED               CC6.1, CC6.8 – key lifecycle management
#   ESSENTIAL_CONTACTS_NOT_CONFIGURED CC2.2 – operational communication
#   KMS_ROLE_SEPARATION               CC6.3 – separation of duties (KMS)
#   SERVICE_ACCOUNT_ROLE_SEPARATION   CC6.3 – separation of duties (SA)
#   ADMIN_SERVICE_ACCOUNT             CC6.3 – least privilege

SHA_MODULES=(
  "CLOUD_ASSET_API_DISABLED"
  "AUDIT_LOGGING_DISABLED"
  "KMS_PUBLIC_KEY"
  "PUBLIC_DATASET"
  "KMS_KEY_NOT_ROTATED"
  "ESSENTIAL_CONTACTS_NOT_CONFIGURED"
  "KMS_ROLE_SEPARATION"
  "SERVICE_ACCOUNT_ROLE_SEPARATION"
  "ADMIN_SERVICE_ACCOUNT"
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

echo "All SOC 2 SHA modules enabled."
