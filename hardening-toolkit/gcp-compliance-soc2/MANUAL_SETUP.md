# Manual Configuration Steps

Since automated setup requires organization access, follow these manual steps:

## Step 1: Grant Service Account Permissions (via Console)

1. **Go to IAM & Admin**: https://console.cloud.google.com/iam-admin/iam
2. **Select your organization** from the dropdown at the top
3. **Click "Grant Access"**
4. **Add principal**: `terraform-sa@seed-prj-470417.iam.gserviceaccount.com`
5. **Assign these roles**:
   - Organization Admin
   - Organization Policy Administrator  
   - Logging Admin
   - Security Admin
   - Monitoring Admin

## Step 2: Grant Yourself Impersonation Permission

1. **Go to Service Accounts**: https://console.cloud.google.com/iam-admin/serviceaccounts?project=seed-prj-470417
2. **Click** on `terraform-sa@seed-prj-470417.iam.gserviceaccount.com`
3. **Go to "Permissions" tab**
4. **Click "Grant Access"**
5. **Add**: `admin@yasirhashmi.altostrat.com`
6. **Role**: Service Account Token Creator
7. **Save**

## Step 3: Get Your Organization ID

```bash
# Via gcloud (if you have org access)
gcloud organizations list

# Or via console
# Go to: https://console.cloud.google.com/iam-admin/settings
# Copy the Organization ID
```

## Step 4: Create Configuration Files

### Create terraform.tfvars

```bash
cd /Users/yasirhashmi/Desktop/IP\ Initiatives/gcp-compliance-soc2

cat > terraform.tfvars <<'EOF'
organization_id      = "YOUR_ORG_ID_HERE"  # Replace with actual org ID
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
```

### Create provider_override.tf

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

## Step 5: Initialize Terraform

```bash
terraform init
```

## Step 6: Plan and Apply

```bash
# Review what will be created
terraform plan

# Apply if everything looks good
terraform apply
```

## Quick Commands

Once permissions are granted, run these commands in order:

```bash
cd /Users/yasirhashmi/Desktop/IP\ Initiatives/gcp-compliance-soc2

# Get org ID
ORG_ID=$(gcloud organizations list --format="value(name)" | head -n 1)
echo "Organization ID: $ORG_ID"

# Create terraform.tfvars (replace ORG_ID_HERE with actual value)
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
allowed_regions = ["us-central1", "us-east1"]
EOF

# Create provider override
cat > provider_override.tf <<'EOF'
provider "google" {
  impersonate_service_account = "terraform-sa@seed-prj-470417.iam.gserviceaccount.com"
  user_project_override       = true
  billing_project             = "seed-prj-470417"
}
EOF

# Initialize and plan
terraform init
terraform plan
```
