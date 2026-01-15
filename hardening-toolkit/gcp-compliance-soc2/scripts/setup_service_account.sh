#!/bin/bash
# Create service account for SOC2 module deployment and grant necessary permissions

set -e

# Configuration
SEED_PROJECT="${1:-direct-volt-467911-r1}"
SA_NAME="soc2-terraform-deployer"
SA_EMAIL="${SA_NAME}@${SEED_PROJECT}.iam.gserviceaccount.com"
SA_DISPLAY_NAME="SOC2 Terraform Deployer"

echo "================================================"
echo "Creating Service Account for SOC2 Deployment"
echo "================================================"
echo ""
echo "Seed Project: $SEED_PROJECT"
echo "Service Account: $SA_EMAIL"
echo ""

# Step 1: Create the service account
echo "Step 1: Creating service account..."
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="$SA_DISPLAY_NAME" \
  --description="Service account for deploying SOC2 compliance controls via Terraform" \
  --project="$SEED_PROJECT" 2>&1 | grep -v "already exists" || echo "Service account already exists, continuing..."

echo "✅ Service account created/verified"
echo ""

# Step 2: Get organization ID
echo "Step 2: Detecting organization..."
ORG_ID=$(gcloud organizations list --format="value(name)" 2>/dev/null | head -n 1)

if [ -z "$ORG_ID" ]; then
  echo "⚠️  WARNING: No organization detected"
  echo "You may need to grant permissions manually via the console"
  echo ""
  echo "Required roles at organization level:"
  echo "  - roles/resourcemanager.organizationAdmin"
  echo "  - roles/orgpolicy.policyAdmin"
  echo "  - roles/logging.configWriter"
  echo "  - roles/iam.securityAdmin"
  echo ""
  exit 1
fi

echo "✅ Organization ID: $ORG_ID"
echo ""

# Step 3: Grant organization-level permissions
echo "Step 3: Granting organization-level permissions..."

ORG_ROLES=(
  "roles/resourcemanager.organizationAdmin"
  "roles/orgpolicy.policyAdmin"
  "roles/logging.configWriter"
  "roles/iam.securityAdmin"
  "roles/monitoring.admin"
)

for role in "${ORG_ROLES[@]}"; do
  echo "  Granting $role..."
  gcloud organizations add-iam-policy-binding "$ORG_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$role" \
    --condition=None \
    --quiet 2>&1 | grep -v "already exists" || true
done

echo "✅ Organization-level permissions granted"
echo ""

# Step 4: Grant project-level permissions (for audit project)
echo "Step 4: Granting project-level permissions..."

PROJECT_ROLES=(
  "roles/storage.admin"
  "roles/bigquery.admin"
  "roles/logging.admin"
  "roles/monitoring.admin"
  "roles/iam.serviceAccountAdmin"
)

for role in "${PROJECT_ROLES[@]}"; do
  echo "  Granting $role on project $SEED_PROJECT..."
  gcloud projects add-iam-policy-binding "$SEED_PROJECT" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$role" \
    --quiet 2>&1 | grep -v "already exists" || true
done

echo "✅ Project-level permissions granted"
echo ""

# Step 5: Grant your user permission to impersonate the service account
echo "Step 5: Granting impersonation permissions..."

USER_EMAIL=$(gcloud config get-value account)
echo "  Granting serviceAccountTokenCreator to $USER_EMAIL..."

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --member="user:$USER_EMAIL" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --project="$SEED_PROJECT" \
  --quiet

echo "✅ Impersonation permissions granted"
echo ""

# Step 6: Create key file (optional, for Terraform)
echo "Step 6: Creating service account key..."
KEY_FILE="$HOME/.gcp/soc2-terraform-sa-key.json"
mkdir -p "$HOME/.gcp"

if [ -f "$KEY_FILE" ]; then
  echo "  Key file already exists at $KEY_FILE"
else
  gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL" \
    --project="$SEED_PROJECT"
  echo "✅ Key file created: $KEY_FILE"
fi

echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "Service Account: $SA_EMAIL"
echo "Organization ID: $ORG_ID"
echo "Key File: $KEY_FILE"
echo ""
echo "Next steps:"
echo ""
echo "Option 1: Use service account impersonation (recommended)"
echo "  export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=$SA_EMAIL"
echo "  terraform plan"
echo ""
echo "Option 2: Use service account key"
echo "  export GOOGLE_APPLICATION_CREDENTIALS=$KEY_FILE"
echo "  terraform plan"
echo ""
echo "Option 3: Configure in provider block (add to main.tf):"
echo "  provider \"google\" {"
echo "    impersonate_service_account = \"$SA_EMAIL\""
echo "  }"
echo ""
