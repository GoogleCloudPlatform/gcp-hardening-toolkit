# Fixing Deployment Errors

## Current Errors

1. ❌ **Organization Policy API not enabled** in seed-prj-470417
2. ❌ **Service account needs Service Usage Consumer role**

## Fix Steps

### Option 1: Enable APIs via Console (Recommended - Fastest)

1. **Enable Organization Policy API**:
   - Go to: https://console.developers.google.com/apis/api/orgpolicy.googleapis.com/overview?project=seed-prj-470417
   - Click **"ENABLE"**

2. **Enable other required APIs**:
   - Go to: https://console.cloud.google.com/apis/library?project=seed-prj-470417
   - Search and enable:
     - Cloud Resource Manager API
     - Cloud Logging API
     - Cloud Monitoring API
     - BigQuery API
     - Cloud Storage API

3. **Grant Service Usage Consumer role to service account**:
   - Go to: https://console.cloud.google.com/iam-admin/iam?project=seed-prj-470417
   - Find `terraform-sa@seed-prj-470417.iam.gserviceaccount.com`
   - Click "Edit" (pencil icon)
   - Click "ADD ANOTHER ROLE"
   - Select: **Service Usage Consumer**
   - Click "SAVE"

4. **Retry deployment**:
   ```bash
   terraform apply --auto-approve
   ```

### Option 2: Try Script (May have permission issues)

```bash
./scripts/enable_required_apis.sh
```

If this fails, use Option 1 (Console) instead.

---

## Quick Links

- **Enable Org Policy API**: https://console.developers.google.com/apis/api/orgpolicy.googleapis.com/overview?project=seed-prj-470417
- **API Library**: https://console.cloud.google.com/apis/library?project=seed-prj-470417
- **IAM Page**: https://console.cloud.google.com/iam-admin/iam?project=seed-prj-470417

---

## After Fixing

Once you've enabled the APIs and granted the role:

```bash
# Wait 1-2 minutes for permissions to propagate
sleep 120

# Retry deployment
terraform apply --auto-approve
```

## Expected Result

After fixing, you should see:
- ✅ 14 organization policies created
- ✅ Audit log bucket created
- ✅ BigQuery dataset created
- ✅ 4 alert policies created
