# Service Account Setup for Organization Admins

This guide is for **Organization Administrators** who need to set up the Terraform service account for SOC2 compliance deployment.

## Overview

The SOC2 compliance module uses a dedicated service account for Terraform operations. This follows the principle of least privilege and provides better audit trails. However, this service account needs organization-level permissions that can only be granted by an Organization Admin.

## Prerequisites

- You must have `roles/resourcemanager.organizationAdmin` or equivalent permissions
- The service account must already exist in a project (typically the audit/quota project)
- You need the organization ID and service account email

## Required Roles

The Terraform service account needs the following organization-level roles:

| Role | Purpose |
|------|---------|
| `roles/orgpolicy.policyAdmin` | Create and manage organization policies |
| `roles/logging.configWriter` | Configure organization-level log sinks |
| `roles/iam.organizationRoleAdmin` | Manage IAM audit configurations |
| `roles/resourcemanager.organizationAdmin` | Access to organization resources |

## Setup Methods

### Option 1: Using the Helper Script (Recommended)

We provide a script that grants all required roles:

```bash
cd scripts
./grant_sa_roles.sh <ORG_ID> <SERVICE_ACCOUNT_EMAIL>
```

**Example:**
```bash
./grant_sa_roles.sh 858770860297 terraform-soc2@seed-prj-470417.iam.gserviceaccount.com
```

The script will:
1. Show you what roles will be granted
2. Ask for confirmation
3. Grant all roles
4. Confirm successful completion

### Option 2: Manual Role Grants

If you prefer to grant roles manually:

```bash
ORG_ID="your-org-id"
SA_EMAIL="terraform-soc2@your-project.iam.gserviceaccount.com"

# Grant Organization Policy Admin
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/orgpolicy.policyAdmin"

# Grant Logging Config Writer
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/logging.configWriter"

# Grant Organization Role Admin
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/iam.organizationRoleAdmin"

# Grant Organization Admin
gcloud organizations add-iam-policy-binding "$ORG_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/resourcemanager.organizationAdmin"
```

## Additional Setup for Terraform Users

After the org admin grants the roles, the **Terraform user** (person running `terraform apply`) needs permission to impersonate the service account:

```bash
PROJECT_ID="your-audit-project"
SA_EMAIL="terraform-soc2@your-project.iam.gserviceaccount.com"
USER_EMAIL="user@example.com"

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --member="user:$USER_EMAIL" \
  --role="roles/iam.serviceAccountTokenCreator"
```

## Alternative: Using User Credentials

If you want to avoid service account setup entirely, users can run Terraform with their own credentials:

1. **Set `terraform_service_account = null`** in `terraform.tfvars` (or omit it entirely)
2. **Run:** `gcloud auth application-default login`
3. **Ensure the user has all the required org-level roles listed above**

**Trade-offs:**
- ✅ Simpler setup (no service account needed)
- ✅ Faster to get started
- ❌ User needs powerful org-level permissions
- ❌ Less suitable for production/CI-CD
- ❌ Harder to audit (changes tied to individual users)

## Verification

To verify the service account has the correct permissions:

```bash
# List all IAM bindings for the service account at org level
gcloud organizations get-iam-policy <ORG_ID> \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:<SA_EMAIL>"
```

You should see all four roles listed above.

## Security Considerations

1. **Least Privilege**: The service account only has the minimum permissions needed for SOC2 compliance
2. **Audit Trail**: All Terraform changes are attributed to the service account, not individual users
3. **Separation of Duties**: Org admins grant roles, Terraform users impersonate the SA
4. **Project Isolation**: The service account should be in the audit/quota project (same as where logs are stored)

## Troubleshooting

### "Permission denied" errors during terraform apply

**Cause**: Service account is missing required roles

**Solution**: Re-run the `grant_sa_roles.sh` script or manually verify all roles are granted

### "Error impersonating service account"

**Cause**: Your user doesn't have `roles/iam.serviceAccountTokenCreator` on the SA

**Solution**: Ask a project admin to grant you this role on the service account

### "Service account not found"

**Cause**: The service account doesn't exist or is in a different project

**Solution**: Verify the service account email and ensure it exists in the quota project
