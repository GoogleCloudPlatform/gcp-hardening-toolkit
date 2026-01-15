#!/bin/bash
# Enable required APIs in seed-prj-470417

PROJECT_ID="seed-prj-470417"

echo "Enabling required APIs in $PROJECT_ID..."
echo ""

# List of APIs to enable
APIS=(
  "orgpolicy.googleapis.com"
  "cloudresourcemanager.googleapis.com"
  "logging.googleapis.com"
  "monitoring.googleapis.com"
  "bigquery.googleapis.com"
  "storage.googleapis.com"
  "iam.googleapis.com"
)

for api in "${APIS[@]}"; do
  echo "Enabling $api..."
  gcloud services enable "$api" \
    --project="$PROJECT_ID" \
    --impersonate-service-account="terraform-sa@seed-prj-470417.iam.gserviceaccount.com" \
    2>&1 || echo "  ⚠️  Failed to enable $api (may need manual enablement)"
done

echo ""
echo "✅ API enablement complete"
echo ""
echo "If any APIs failed to enable, please enable them manually at:"
echo "https://console.cloud.google.com/apis/library?project=$PROJECT_ID"
