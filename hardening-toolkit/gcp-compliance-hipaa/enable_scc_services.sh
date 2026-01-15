#!/bin/bash

# Set your organization ID and quota project here
ORGANIZATION_ID="YOUR_ORGANIZATION_ID"
QUOTA_PROJECT="YOUR_QUOTA_PROJECT"

# A list of Security Command Center services to enable.
# PLEASE NOTE: These service names are best guesses. Please verify them before running the script.
SCC_SERVICES=(
  "event-threat-detection"
  "security-health-analytics"
  "web-security-scanner"
  "container-threat-detection"
  "virtual-machine-threat-detection"
)

for service in "${SCC_SERVICES[@]}"; do
  echo "Enabling $service..."
  gcloud alpha scc settings services enable \
    --service="$service" \
    --organization="$ORGANIZATION_ID" \
    --billing-project="$QUOTA_PROJECT"
  echo "$service enabled."
  echo ""
done

echo "All services enabled."

