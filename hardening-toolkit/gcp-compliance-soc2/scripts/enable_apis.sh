#!/bin/bash
# Enable required GCP APIs for SOC2 module testing

set -e

PROJECT_ID="${1:-direct-volt-467911-r1}"

echo "================================================"
echo "Enabling required APIs for SOC2 module"
echo "Project: $PROJECT_ID"
echo "================================================"
echo ""

# List of required APIs
APIS=(
  "cloudresourcemanager.googleapis.com"
  "orgpolicy.googleapis.com"
  "logging.googleapis.com"
  "monitoring.googleapis.com"
  "bigquery.googleapis.com"
  "storage.googleapis.com"
  "iam.googleapis.com"
)

for api in "${APIS[@]}"; do
  echo "Enabling $api..."
  gcloud services enable "$api" --project="$PROJECT_ID" 2>&1 | grep -v "already enabled" || true
done

echo ""
echo "================================================"
echo "✅ All required APIs enabled successfully!"
echo "================================================"
echo ""

# Check current permissions
echo "Checking your permissions..."
echo ""

# Check if user has org access
ORG_ID=$(gcloud organizations list --format="value(name)" 2>/dev/null | head -n 1)

if [ -z "$ORG_ID" ]; then
  echo "⚠️  WARNING: No organization access detected"
  echo ""
  echo "The SOC2 module requires organization-level permissions to deploy"
  echo "organization policies. You have the following options:"
  echo ""
  echo "1. Request organization admin access from your Argolis administrator"
  echo "2. Use 'terraform plan' to validate configuration without deployment"
  echo "3. Test individual modules at project level"
  echo ""
  echo "For now, you can validate the Terraform configuration:"
  echo "  cd /Users/yasirhashmi/Desktop/IP\ Initiatives/gcp-compliance-soc2"
  echo "  terraform init"
  echo "  terraform validate"
  echo ""
else
  echo "✅ Organization access detected: $ORG_ID"
  echo ""
  echo "You can proceed with full deployment!"
  echo ""
fi

echo "Next steps:"
echo "1. Copy terraform.tfvars.example to terraform.tfvars"
echo "2. Update the values in terraform.tfvars"
echo "3. Run: terraform init"
echo "4. Run: terraform plan"
echo ""
