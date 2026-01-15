#!/bin/bash
################################################################################
# Service Account Role Grant Script
# 
# This script must be run by an Organization Admin to grant the necessary
# roles to the Terraform service account for SOC2 compliance deployment.
#
# Usage:
#   ./grant_sa_roles.sh <ORG_ID> <SERVICE_ACCOUNT_EMAIL>
#
# Example:
#   ./grant_sa_roles.sh 858770860297 terraform-soc2@seed-prj-470417.iam.gserviceaccount.com
################################################################################

set -e

# Check arguments
if [ $# -ne 2 ]; then
  echo "Usage: $0 <ORG_ID> <SERVICE_ACCOUNT_EMAIL>"
  echo ""
  echo "Example:"
  echo "  $0 858770860297 terraform-soc2@seed-prj-470417.iam.gserviceaccount.com"
  exit 1
fi

ORG_ID=$1
SA_EMAIL=$2

echo "========================================="
echo "SOC2 Service Account Role Grant"
echo "========================================="
echo "Organization ID: $ORG_ID"
echo "Service Account: $SA_EMAIL"
echo ""
echo "This script will grant the following roles:"
echo "  - roles/orgpolicy.policyAdmin"
echo "  - roles/logging.configWriter"
echo "  - roles/iam.organizationRoleAdmin"
echo "  - roles/resourcemanager.organizationAdmin"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 1
fi

echo ""
echo "Granting roles..."

# Grant Organization Policy Admin
echo "  ✓ Granting roles/orgpolicy.policyAdmin..."
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/orgpolicy.policyAdmin" \
  --condition=None \
  > /dev/null 2>&1

# Grant Logging Config Writer
echo "  ✓ Granting roles/logging.configWriter..."
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/logging.configWriter" \
  --condition=None \
  > /dev/null 2>&1

# Grant Organization Role Admin
echo "  ✓ Granting roles/iam.organizationRoleAdmin..."
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.organizationRoleAdmin" \
  --condition=None \
  > /dev/null 2>&1

# Grant Organization Admin (for audit config)
echo "  ✓ Granting roles/resourcemanager.organizationAdmin..."
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/resourcemanager.organizationAdmin" \
  --condition=None \
  > /dev/null 2>&1

echo ""
echo "========================================="
echo "✅ All roles granted successfully!"
echo "========================================="
echo ""
echo "The service account can now be used for Terraform impersonation."
echo "Next steps:"
echo "  1. Ensure your user has 'roles/iam.serviceAccountTokenCreator' on the SA"
echo "  2. Set terraform_service_account in terraform.tfvars"
echo "  3. Run: terraform init && terraform plan"
