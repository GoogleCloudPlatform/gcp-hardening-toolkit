# SOC2 Module Testing Guide - Argolis Environment

## Current Environment Status

**Project**: `direct-volt-467911-r1`
**Organization Access**: ❌ Not available
**Issue**: SOC2 module requires organization-level permissions to deploy organization policies

## Testing Options

### Option 1: Request Organization Access (Recommended for Full Testing)

To test the full SOC2 module, you need:
1. Access to a GCP organization
2. The following roles:
   - `roles/resourcemanager.organizationAdmin`
   - `roles/orgpolicy.policyAdmin`
   - `roles/logging.configWriter`

**Steps to request access:**
```bash
# Contact your Argolis administrator to grant organization-level access
# Or use a different Argolis environment with org access
```

### Option 2: Project-Level Testing (Limited Scope)

Test individual components that work at project level:
- ✅ Audit logging configuration
- ✅ Monitoring and alerting
- ❌ Organization policies (requires org access)

### Option 3: Use Terraform Plan Mode (No Deployment)

Test the Terraform configuration without actually deploying:
```bash
# This will validate syntax and show what would be created
terraform init
terraform plan
```

## Quick Start: Project-Level Testing

I'll create a simplified version that tests audit logging and monitoring in your current project.

### Step 1: Create Test Configuration

```bash
cd /Users/yasirhashmi/Desktop/IP\ Initiatives/gcp-compliance-soc2

# Create a test-specific tfvars file
cat > test-argolis.tfvars <<EOF
# Use your current project for testing
organization_id      = "000000000000"  # Placeholder (won't be used)
quota_project        = "direct-volt-467911-r1"
audit_project_id     = "direct-volt-467911-r1"
log_bucket_location  = "us-central1"

# Disable org-level controls for testing
enabled_criteria = {
  security        = false  # Requires org access
  availability    = false  # Requires org access
  confidentiality = false  # Requires org access
}

# Notification email
security_team_email = "admin@yasirhashmi.altostrat.com"
EOF
```

### Step 2: Enable Required APIs

```bash
# Enable APIs needed for audit logging and monitoring
gcloud services enable logging.googleapis.com --project=direct-volt-467911-r1
gcloud services enable monitoring.googleapis.com --project=direct-volt-467911-r1
gcloud services enable bigquery.googleapis.com --project=direct-volt-467911-r1
gcloud services enable storage.googleapis.com --project=direct-volt-467911-r1
```

### Step 3: Test with Terraform Plan

```bash
terraform init
terraform plan -var-file=test-argolis.tfvars
```

## Recommended Approach for Full Testing

### Use Google Cloud Console

1. **Navigate to Organization Policies**:
   - Go to https://console.cloud.google.com/iam-admin/orgpolicies
   - Check if you have access to any organization

2. **Check Folder Access**:
   ```bash
   gcloud resource-manager folders list --organization=<ORG_ID>
   ```

3. **Test in a Folder** (if you have folder admin access):
   - Modify the module to use `folder_id` instead of `organization_id`
   - Deploy policies at folder level

### Alternative: Use Terraform Cloud/Workspace

If you have access to a different GCP organization through Terraform Cloud:
1. Configure remote backend
2. Use organization credentials
3. Deploy to test organization

## What You Can Test Right Now

Even without org access, you can:

### 1. Validate Terraform Code
```bash
cd /Users/yasirhashmi/Desktop/IP\ Initiatives/gcp-compliance-soc2
terraform init
terraform validate
terraform fmt -check -recursive
```

### 2. Review Generated Plan
```bash
# This shows what WOULD be created (won't actually deploy)
terraform plan -var-file=test-argolis.tfvars
```

### 3. Test Individual Modules
```bash
# Test just the audit logging module
cd modules/audit-logging
terraform init
terraform plan \
  -var="organization_id=000000000000" \
  -var="audit_project_id=direct-volt-467911-r1" \
  -var="log_bucket_location=us-central1"
```

## Next Steps

**Choose one:**

1. **Request org access** from Argolis admin for full testing
2. **Use terraform plan** to validate configuration without deployment
3. **Deploy to a different environment** where you have org admin rights
4. **Test individual components** at project level

Would you like me to:
- Create a project-level test version?
- Help you request organization access?
- Set up terraform plan for validation?
