#!/usr/bin/env bash
# Script Name: export_cai_state.sh
# Purpose: Zero-touch CAI state export with deterministic execution validation.

PROJECT_ID=${1:-}
if [[ -z "$PROJECT_ID" ]]; then
  echo "Execution aborted: Project ID is required."
  exit 1
fi

DATASET_NAME="hardening_agent_cai_state"

echo "Ensuring Cloud Asset API is enabled for ${PROJECT_ID}..."
gcloud services enable cloudasset.googleapis.com --project="${PROJECT_ID}" --quiet

echo "Ensuring standardized BigQuery dataset '${DATASET_NAME}' exists..."
bq mk --force --dataset "${PROJECT_ID}:${DATASET_NAME}" 2>/dev/null || true

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TABLE_NAME="cai_state_${TIMESTAMP}"
FULLY_QUALIFIED_TABLE="projects/${PROJECT_ID}/datasets/${DATASET_NAME}/tables/${TABLE_NAME}"

IAM_TABLE_NAME="iam_policy_${TIMESTAMP}"
FULLY_QUALIFIED_IAM_TABLE="projects/${PROJECT_ID}/datasets/${DATASET_NAME}/tables/${IAM_TABLE_NAME}"

echo "Initiating CAI batch export to BigQuery table: ${DATASET_NAME}.${TABLE_NAME}..."

# Execute the resource export and capture the asynchronous output
EXPORT_OUT=$(gcloud asset export \
  --project="${PROJECT_ID}" \
  --asset-types="compute.googleapis.com/Instance,compute.googleapis.com/Firewall,iam.googleapis.com/ServiceAccount" \
  --content-type=resource \
  --bigquery-table="${FULLY_QUALIFIED_TABLE}" \
  --output-bigquery-force 2>&1)

# Echo the output so you have visibility
echo "$EXPORT_OUT"

# Extract the operation path using Regex
OP_PATH=$(echo "$EXPORT_OUT" | grep -oE "projects/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

echo "Initiating IAM policy export to BigQuery table: ${DATASET_NAME}.${IAM_TABLE_NAME}..."

# Execute the IAM export and capture the asynchronous output
EXPORT_IAM_OUT=$(gcloud asset export \
  --project="${PROJECT_ID}" \
  --content-type=iam-policy \
  --bigquery-table="${FULLY_QUALIFIED_IAM_TABLE}" \
  --output-bigquery-force 2>&1)

# Echo the output so you have visibility
echo "$EXPORT_IAM_OUT"

# Extract the operation path using Regex
OP_PATH_IAM=$(echo "$EXPORT_IAM_OUT" | grep -oE "projects/[0-9]+/operations/ExportAssets/[a-zA-Z_]+/[a-f0-9]+")

if [[ -z "$OP_PATH" ]] || [[ -z "$OP_PATH_IAM" ]]; then
  echo "Execution aborted: Failed to extract operation path for one or both exports. Review the logs above."
  exit 1
fi

echo "Exports triggered."
echo "To check resource export status: gcloud asset operations describe \"${OP_PATH}\""
echo "To check IAM policy export status: gcloud asset operations describe \"${OP_PATH_IAM}\""
echo "Once operations are complete, tables ${DATASET_NAME}.${TABLE_NAME} and ${DATASET_NAME}.${IAM_TABLE_NAME} will be populated."
