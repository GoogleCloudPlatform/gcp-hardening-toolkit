# Quick Deployment Guide

## Step 1: Get Your Organization ID

Go to the Cloud Console and get your organization ID:
https://console.cloud.google.com/iam-admin/settings?project=seed-prj-470417

Copy the **Organization ID** (it will be a number like `123456789012`)

## Step 2: Create terraform.tfvars

Run this command and **replace `YOUR_ORG_ID_HERE`** with the actual organization ID:

```bash
cd /Users/yasirhashmi/Desktop/IP\ Initiatives/gcp-compliance-soc2

cat > terraform.tfvars <<'EOF'
organization_id      = "YOUR_ORG_ID_HERE"
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

## Step 3: Initialize Terraform

```bash
terraform init
```

## Step 4: Review the Plan

```bash
terraform plan
```

This will show you everything that will be created. Review it carefully!

## Step 5: Apply

If the plan looks good:

```bash
terraform apply
```

Type `yes` when prompted.

## What Will Be Created

- **14 Organization Policies** for SOC2 compliance
- **Audit log bucket** in Cloud Storage
- **BigQuery dataset** for log analysis
- **4 Security alert policies**
- **Email notifications** to admin@yasirhashmi.altostrat.com

## Verification

After deployment, verify:

```bash
# Check outputs
terraform output

# List organization policies (via console)
# Go to: https://console.cloud.google.com/iam-admin/orgpolicies
```

## Troubleshooting

If you get errors about missing APIs, enable them via console:
https://console.cloud.google.com/apis/library?project=seed-prj-470417

Required APIs:
- Cloud Resource Manager API
- Organization Policy API
- Cloud Logging API
- Cloud Monitoring API
- BigQuery API
- Cloud Storage API
