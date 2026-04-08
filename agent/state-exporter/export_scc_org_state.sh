#!/usr/bin/env bash
# Script Name: export_scc_org_state.sh
# Purpose: Org-wide SCC findings export to Cloud Storage with billing project delegation.

ORG_ID=${1:-}
BILLING_PROJECT=${2:-}
BUCKET_NAME=${3:-"hardening-agent-org-scc-state-${BILLING_PROJECT}"}

if [[ -z "$ORG_ID" || -z "$BILLING_PROJECT" ]]; then
  echo "Execution aborted: Organization ID and Billing Project ID are required."
  echo "Usage: $0 <ORG_ID> <BILLING_PROJECT_ID> [BUCKET_NAME]"
  exit 1
fi

echo "Ensuring Security Command Center API is enabled in billing project: ${BILLING_PROJECT}..."
gcloud services enable securitycenter.googleapis.com --project="${BILLING_PROJECT}" --quiet

echo "Ensuring Cloud Storage bucket '${BUCKET_NAME}' exists in ${BILLING_PROJECT}..."
gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${BILLING_PROJECT}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE_NAME="scc_findings_org_${ORG_ID}_${TIMESTAMP}.json"
GCS_PATH="gs://${BUCKET_NAME}/${FILE_NAME}"

echo "Initiating Organization-wide SCC findings export for Org: ${ORG_ID} to ${GCS_PATH} using SCC V2 API..."

# List findings in JSON format and stream to GCS
# Added --location=global to force usage of SCC V2 API.
gcloud scc findings list "organizations/${ORG_ID}" \
  --location="global" \
  --billing-project="${BILLING_PROJECT}" \
  --format="json" > "/tmp/${FILE_NAME}"

if [[ $? -ne 0 ]]; then
  echo "Error: Failed to list SCC findings. Ensure you have the required permissions and that the SCC V2 API is available."
  rm -f "/tmp/${FILE_NAME}"
  exit 1
fi

gcloud storage cp "/tmp/${FILE_NAME}" "${GCS_PATH}"

if [[ $? -eq 0 ]]; then
  echo "Export complete: ${GCS_PATH}"
else
  echo "Error: Failed to upload to Cloud Storage."
  rm -f "/tmp/${FILE_NAME}"
  exit 1
fi

rm "/tmp/${FILE_NAME}"
