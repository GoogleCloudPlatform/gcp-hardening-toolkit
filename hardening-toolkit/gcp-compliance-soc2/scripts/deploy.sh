#!/bin/bash
# Complete setup script for SOC2 module deployment

set -e

echo "================================================"
echo "SOC2 Module - Complete Setup"
echo "================================================"
echo ""

# Step 1: Check if Terraform is installed
echo "Step 1: Checking Terraform installation..."
if ! command -v terraform &> /dev/null; then
    echo "Terraform not found. Installing..."
    
    # Install Terraform using Homebrew (macOS)
    if command -v brew &> /dev/null; then
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
    else
        echo "❌ Homebrew not found. Please install Terraform manually:"
        echo "   https://developer.hashicorp.com/terraform/downloads"
        exit 1
    fi
else
    echo "✅ Terraform is installed: $(terraform version | head -n 1)"
fi

echo ""

# Step 2: Get organization ID
echo "Step 2: Getting organization ID..."
echo "Please enter your GCP Organization ID"
echo "(Get it from: https://console.cloud.google.com/iam-admin/settings?project=seed-prj-470417)"
read -p "Organization ID: " ORG_ID

if [ -z "$ORG_ID" ]; then
    echo "❌ Organization ID is required"
    exit 1
fi

echo "✅ Using Organization ID: $ORG_ID"
echo ""

# Step 3: Create terraform.tfvars
echo "Step 3: Creating terraform.tfvars..."

cat > terraform.tfvars <<EOF
organization_id      = "$ORG_ID"
quota_project        = "seed-prj-470417"
audit_project_id     = "seed-prj-470417"
log_bucket_location  = "us-central1"

enabled_criteria = {
  security        = true
  availability    = true
  confidentiality = true
}

security_team_email = "admin@yasirhashmi.altostrat.com"

allowed_regions = [
  "us-central1",
  "us-east1"
]
EOF

echo "✅ Created terraform.tfvars"
echo ""

# Step 4: Initialize Terraform
echo "Step 4: Initializing Terraform..."
terraform init

echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Review what will be created:"
echo "   terraform plan"
echo ""
echo "2. Deploy the SOC2 controls:"
echo "   terraform apply"
echo ""
echo "Configuration:"
echo "  Organization: $ORG_ID"
echo "  Seed Project: seed-prj-470417"
echo "  Service Account: terraform-sa@seed-prj-470417.iam.gserviceaccount.com"
echo ""
