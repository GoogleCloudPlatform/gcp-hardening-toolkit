# Quick Start Guide - Testing SOC2 Module in Argolis

## Service Account Setup

**Service Account**: `terraform-sa@seed-prj-470417.iam.gserviceaccount.com`  
**Seed Project**: `seed-prj-470417`

## Option 1: Automated Setup (Recommended)

Run the quick setup script:

```bash
cd /Users/yasirhashmi/Desktop/IP\ Initiatives/gcp-compliance-soc2
./scripts/quick_setup.sh
```

This will:
1. Detect your organization ID
2. Create `terraform.tfvars` with correct values
3. Create `provider_override.tf` for service account impersonation
4. Initialize Terraform

Then proceed with:
```bash
terraform plan
terraform apply
```

## Option 2: Manual Setup

### Step 1: Get Organization ID

```bash
# Try with service account impersonation
gcloud organizations list \
  --impersonate-service-account=terraform-sa@seed-prj-470417.iam.gserviceaccount.com

# Or via console: https://console.cloud.google.com/iam-admin/settings
```

### Step 2: Create terraform.tfvars

```bash
cat > terraform.tfvars <<'EOF'
organization_id      = "<YOUR_ORG_ID>"  # From step 1
quota_project        = "seed-prj-470417"
audit_project_id     = "seed-prj-470417"
log_bucket_location  = "us-central1"

enabled_criteria = {
  security        = true
  availability    = true
  confidentiality = true
}

security_team_email = "admin@yasirhashmi.altostrat.com"

allowed_regions = ["us-central1", "us-east1"]
EOF
```

### Step 3: Configure Service Account Impersonation

Create `provider_override.tf`:

```bash
cat > provider_override.tf <<'EOF'
provider "google" {
  impersonate_service_account = "terraform-sa@seed-prj-470417.iam.gserviceaccount.com"
  user_project_override       = true
  billing_project             = "seed-prj-470417"
}

provider "google-beta" {
  impersonate_service_account = "terraform-sa@seed-prj-470417.iam.gserviceaccount.com"
  user_project_override       = true
  billing_project             = "seed-prj-470417"
}
EOF
```

### Step 4: Initialize and Test

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# See what will be created
terraform plan

# Apply if everything looks good
terraform apply
```

## Troubleshooting

### Issue: "No organization access"

**Solution**: Ensure the service account `terraform-sa@seed-prj-470417.iam.gserviceaccount.com` has these roles at the organization level:
- `roles/resourcemanager.organizationAdmin`
- `roles/orgpolicy.policyAdmin`
- `roles/logging.configWriter`
- `roles/iam.securityAdmin`

Grant via console: https://console.cloud.google.com/iam-admin/iam

### Issue: "Permission denied" when impersonating

**Solution**: Grant yourself permission to impersonate the service account:

Via Console:
1. Go to https://console.cloud.google.com/iam-admin/serviceaccounts?project=seed-prj-470417
2. Click on `terraform-sa@seed-prj-470417.iam.gserviceaccount.com`
3. Go to "Permissions" tab
4. Click "Grant Access"
5. Add your email: `admin@yasirhashmi.altostrat.com`
6. Role: `Service Account Token Creator`

### Issue: Quota project errors

**Solution**: The provider configuration in `provider_override.tf` handles this by setting `billing_project = "seed-prj-470417"`

## What Gets Deployed

When you run `terraform apply`, the module will create:

### Organization Policies (14 total)
- **Security**: 7 policies (IAM restrictions, public IP blocks, OS Login, etc.)
- **Availability**: 2 policies (resource locations, backup enforcement)
- **Confidentiality**: 5 policies (encryption, bucket security, VPC controls)

### Audit Logging
- Organization-level audit logs (all types)
- Cloud Storage bucket: `<org-id>-soc2-audit-logs`
- BigQuery dataset: `soc2_audit_logs`
- 365-day retention

### Monitoring & Alerts
- 4 security alert policies
- Email notifications to `admin@yasirhashmi.altostrat.com`

## Verification

After deployment, verify:

```bash
# Check organization policies
gcloud org-policies list \
  --organization=<YOUR_ORG_ID> \
  --impersonate-service-account=terraform-sa@seed-prj-470417.iam.gserviceaccount.com

# Check audit log bucket
gsutil ls gs://<org-id>-soc2-audit-logs/

# Check BigQuery dataset
bq ls --project_id=seed-prj-470417 soc2_audit_logs

# Check alert policies
gcloud alpha monitoring policies list \
  --project=seed-prj-470417 \
  --impersonate-service-account=terraform-sa@seed-prj-470417.iam.gserviceaccount.com
```

## Next Steps

1. Run the quick setup script or follow manual steps
2. Review the Terraform plan carefully
3. Apply to deploy SOC2 controls
4. Verify deployment using commands above
5. Test by attempting to violate a policy (e.g., create VM with public IP)
