#!/bin/bash
# Quick setup script for testing SOC2 module with service account impersonation

set -e

SA_EMAIL="terraform-sa@seed-prj-470417.iam.gserviceaccount.com"
SEED_PROJECT="seed-prj-470417"

echo "================================================"
echo "SOC2 Module - Quick Setup for Argolis Testing"
echo "================================================"
echo ""
echo "Service Account: $SA_EMAIL"
echo "Seed Project: $SEED_PROJECT"
echo ""

# Step 1: Get organization ID
echo "Step 1: Getting organization ID..."
ORG_ID=$(gcloud organizations list --format="value(name)" --impersonate-service-account="$SA_EMAIL" 2>/dev/null | head -n 1)

if [ -z "$ORG_ID" ]; then
  echo "⚠️  Could not detect organization. Trying without impersonation..."
  ORG_ID=$(gcloud organizations list --format="value(name)" 2>/dev/null | head -n 1)
fi

if [ -z "$ORG_ID" ]; then
  echo "❌ No organization access detected"
  echo ""
  echo "Please ensure the service account has organization-level permissions:"
  echo "  - roles/resourcemanager.organizationAdmin"
  echo "  - roles/orgpolicy.policyAdmin"
  echo "  - roles/logging.configWriter"
  echo ""
  exit 1
fi

echo "✅ Organization ID: $ORG_ID"
echo ""

# Step 2: Create terraform.tfvars
echo "Step 2: Creating terraform.tfvars..."

cat > terraform.tfvars <<EOF
# SOC2 Module Configuration for Argolis
organization_id      = "$ORG_ID"
quota_project        = "$SEED_PROJECT"
audit_project_id     = "$SEED_PROJECT"
log_bucket_location  = "us-central1"

# Enable SOC2 criteria
enabled_criteria = {
  security        = true
  availability    = true
  confidentiality = true
}

# Notification email
security_team_email = "admin@yasirhashmi.altostrat.com"

# Allowed regions
allowed_regions = [
  "us-central1",
  "us-east1"
]
EOF

echo "✅ Created terraform.tfvars"
echo ""

# Step 3: Set up Terraform to use service account impersonation
echo "Step 3: Configuring Terraform provider..."

cat > provider_override.tf <<EOF
# Provider configuration for service account impersonation
# This file overrides the provider settings in main.tf

provider "google" {
  impersonate_service_account = "$SA_EMAIL"
  user_project_override       = true
  billing_project             = "$SEED_PROJECT"
}

provider "google-beta" {
  impersonate_service_account = "$SA_EMAIL"
  user_project_override       = true
  billing_project             = "$SEED_PROJECT"
}
EOF

echo "✅ Created provider_override.tf"
echo ""

# Step 4: Initialize Terraform
echo "Step 4: Initializing Terraform..."
terraform init

echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "Configuration:"
echo "  Organization: $ORG_ID"
echo "  Seed Project: $SEED_PROJECT"
echo "  Service Account: $SA_EMAIL"
echo ""
echo "Next steps:"
echo ""
echo "1. Review the configuration:"
echo "   cat terraform.tfvars"
echo ""
echo "2. Run Terraform plan:"
echo "   terraform plan"
echo ""
echo "3. If plan looks good, apply:"
echo "   terraform apply"
echo ""
echo "Note: All operations will use service account impersonation"
echo ""
