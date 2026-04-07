#!/usr/bin/env bash
# Script Name: export_scc_state.sh
# Purpose: Project-level SCC findings export to Cloud Storage.

PROJECT_ID=${1:-}
BUCKET_NAME=${2:-"hardening-agent-scc-state-${PROJECT_ID}"}

if [[ -z "$PROJECT_ID" ]]; then
  echo "Execution aborted: Project ID is required."
  echo "Usage: $0 <PROJECT_ID> [BUCKET_NAME]"
  exit 1
fi

echo "Ensuring Security Command Center API is enabled for ${PROJECT_ID}..."
gcloud services enable securitycenter.googleapis.com --project="${PROJECT_ID}" --quiet

echo "Ensuring Cloud Storage bucket '${BUCKET_NAME}' exists..."
gcloud storage buckets create "gs://${BUCKET_NAME}" --project="${PROJECT_ID}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE_NAME="scc_findings_${PROJECT_ID}_${TIMESTAMP}.json"
GCS_PATH="gs://${BUCKET_NAME}/${FILE_NAME}"

echo "Exporting SCC findings for project ${PROJECT_ID} to ${GCS_PATH} using SCC V2 API..."

# List findings in JSON format and stream to GCS
# Correct syntax: gcloud scc findings list "projects/${PROJECT_ID}"
# Added --location=global to force usage of SCC V2 API, as V1 is being deprecated.
gcloud scc findings list "projects/${PROJECT_ID}" \
  --location="global" \
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
