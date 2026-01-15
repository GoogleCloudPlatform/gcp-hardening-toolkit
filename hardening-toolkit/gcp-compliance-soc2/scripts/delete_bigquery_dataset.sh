#!/bin/bash
# Delete BigQuery dataset and all tables

PROJECT_ID="seed-prj-470417"
DATASET_ID="soc2_audit_logs"

echo "Deleting BigQuery dataset: $DATASET_ID"
echo "This will delete all tables and data in the dataset."
echo ""

# Delete the dataset with all tables
bq rm -r -f -d "$PROJECT_ID:$DATASET_ID"

if [ $? -eq 0 ]; then
  echo "✅ Dataset deleted successfully"
  echo ""
  echo "Now run: terraform apply --auto-approve"
else
  echo "❌ Failed to delete dataset"
  echo ""
  echo "Manual deletion via console:"
  echo "https://console.cloud.google.com/bigquery?project=$PROJECT_ID&p=$PROJECT_ID&d=$DATASET_ID&page=dataset"
fi
