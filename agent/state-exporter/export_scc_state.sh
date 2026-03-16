#!/usr/bin/env bash
# Script Name: export_scc_state.sh
# Purpose: Zero-touch SCC findings state export with deterministic execution validation.

#!/usr/bin/env bash
# Script Name: export_scc_state.sh
# Purpose: Zero-touch SCC findings state export with deterministic execution validation.

PROJECT_ID=${1:-}
ORG_ID=${2:-}
if [[ -z "$PROJECT_ID" || -z "$ORG_ID" ]]; then
  echo "Execution aborted: Project ID and Organization ID are required."
  exit 1
fi

DATASET_NAME="hardening_agent_scc_state"

echo "Ensuring Security Command Center API is enabled for ${PROJECT_ID}..."
gcloud services enable securitycenter.googleapis.com --project="${PROJECT_ID}" --quiet

echo "Ensuring standardized BigQuery dataset '${DATASET_NAME}' exists..."
bq mk --force --dataset "${PROJECT_ID}:${DATASET_NAME}" 2>/dev/null || true

echo "Initiating bulk SCC export to BigQuery dataset: ${DATASET_NAME}..."

EXPORT_OUT=$(gcloud scc findings export-to-bigquery "projects/${PROJECT_ID}" \
  --dataset="projects/${PROJECT_ID}/datasets/${DATASET_NAME}" 2>&1)

# Extract the raw UUID operation name from the output
OP_NAME=$(echo "$EXPORT_OUT" | awk '/^name:/ {print $2}' | tr -d '\r')
RAW_UUID=$(basename "$OP_NAME")

if [[ -z "$RAW_UUID" ]]; then
  echo "Execution aborted: Failed to extract operation ID. API Response:"
  echo "$EXPORT_OUT"
  exit 1
fi

echo "Export triggered."
echo "To check the status of the operation, run: gcloud scc operations describe \"${RAW_UUID}\" --organization=\"${ORG_ID}\""
echo "Once the operation is complete, the data will be in BigQuery dataset: ${DATASET_NAME}."

# The view creation for actionable findings should only happen once the export is confirmed complete.
# Since we are no longer polling, we cannot reliably create this view here.
# User will need to manually check the operation status and then create the view.
# Adding a note to the user to remind them about this.
echo "After the export operation is complete, you can manually create the actionable findings view by running:"
echo "bq query --use_legacy_sql=false --quiet \\"
echo "  \"CREATE OR REPLACE VIEW \`${PROJECT_ID}.${DATASET_NAME}.actionable_findings\` AS \\"
echo "   SELECT * FROM \`${PROJECT_ID}.${DATASET_NAME}.findings\` \\"
echo "   WHERE state = 'ACTIVE' AND severity IN ('HIGH', 'CRITICAL');\""
