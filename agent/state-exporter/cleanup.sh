#!/usr/bin/env bash
# Script Name: cleanup.sh
# Purpose: Deletes the BigQuery dataset and all tables created by the CAI export script.

#!/usr/bin/env bash
# Script Name: cleanup.sh
# Purpose: Deletes the BigQuery dataset and all tables created by the CAI export script.

PROJECT_ID=${1:-}
if [[ -z "$PROJECT_ID" ]]; then
  echo "Execution aborted: Project ID is required."
  exit 1
fi

DATASET_NAME="hardening_agent_cai_state"

echo "Attempting to delete BigQuery dataset '${DATASET_NAME}' from project '${PROJECT_ID}'..."

# Use --recursive to delete all tables within the dataset before deleting the dataset itself.
# Use --force to avoid interactive confirmation prompts.
if bq rm --recursive --force --dataset "${PROJECT_ID}:${DATASET_NAME}"; then
  echo "Cleanup successful: Dataset '${DATASET_NAME}' and its tables have been deleted."
else
  echo "Cleanup failed. The dataset may not have existed or there was an issue with permissions." >&2
  exit 1
fi
