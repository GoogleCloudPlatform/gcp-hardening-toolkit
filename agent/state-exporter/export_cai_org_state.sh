#!/usr/bin/env bash
# Script Name: export_cai_org_state.sh
# Purpose: Org-wide CAI state export with billing project delegation.

ORG_ID=${1:-}
BILLING_PROJECT=${2:-}
DATASET_NAME=${3:-"hardening_agent_org_cai"}

if [[ -z "$ORG_ID" || -z "$BILLING_PROJECT" ]]; then
  echo "Execution aborted: Organization ID and Billing Project ID are required."
  echo "Usage: $0 <ORG_ID> <BILLING_PROJECT_ID> [DATASET_NAME]"
  exit 1
fi

echo "Ensuring Cloud Asset API is enabled in billing project: ${BILLING_PROJECT}..."
gcloud services enable cloudasset.googleapis.com --project="${BILLING_PROJECT}" --quiet

echo "Ensuring BigQuery dataset '${DATASET_NAME}' exists in ${BILLING_PROJECT}..."
bq mk --force --dataset "${BILLING_PROJECT}:${DATASET_NAME}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TABLE_NAME="org_cai_state_${TIMESTAMP}"
# Note: The table path for Org exports uses the 'projects/...' syntax for the destination
FULLY_QUALIFIED_TABLE="projects/${BILLING_PROJECT}/datasets/${DATASET_NAME}/tables/${TABLE_NAME}"

echo "Initiating Organization-wide CAI export for Org: ${ORG_ID}..."

# We use --organization and --billing-project to cross the project boundary
EXPORT_OUT=$(gcloud asset export \
  --organization="${ORG_ID}" \
  --billing-project="${BILLING_PROJECT}" \
  --asset-types="compute.googleapis.com/Instance,compute.googleapis.com/Firewall,iam.googleapis.com/ServiceAccount" \
  --content-type=resource \
  --bigquery-table="${FULLY_QUALIFIED_TABLE}" \
  --output-bigquery-force 2>&1)

echo "$EXPORT_OUT"

# Extract Operation Path
OP_PATH=$(echo "$EXPORT_OUT" | grep -oE "organizations/[0-9]+/operations/ExportAssets/[a-zA-Z]+/[a-f0-9]+")

if [[ -z "$OP_PATH" ]]; then
  echo "Execution aborted: Failed to extract operation path. Check permissions."
  exit 1
fi

echo "----------------------------------------------------------------"
echo "Org Export Triggered successfully."
echo "Check status: gcloud asset operations describe \"${OP_PATH}\" --billing-project=\"${BILLING_PROJECT}\""
echo "Data destination: ${BILLING_PROJECT}.${DATASET_NAME}.${TABLE_NAME}"
