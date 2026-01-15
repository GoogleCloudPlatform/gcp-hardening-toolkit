#!/bin/bash
################################################################################
# Cloud Scheduler Setup for Weekly SA Key Audits
# Automates the execution of audit_sa_keys.sh
################################################################################

set -euo pipefail

PROJECT_ID="${1:-}"
AUDIT_EMAIL="${2:-}"

usage() {
    cat <<EOF
Usage: $0 <PROJECT_ID> <AUDIT_EMAIL>

Sets up Cloud Scheduler to run weekly service account key audits.

Arguments:
    PROJECT_ID      GCP Project ID
    AUDIT_EMAIL     Email to receive audit reports

Example:
    $0 lumen-prod-project security@lumen.com
EOF
    exit 1
}

if [[ -z "$PROJECT_ID" ]] || [[ -z "$AUDIT_EMAIL" ]]; then
    usage
fi

echo "Setting up Cloud Scheduler for SA Key Audits..."

# Enable required APIs
echo "Enabling required APIs..."
gcloud services enable cloudscheduler.googleapis.com --project="$PROJECT_ID"
gcloud services enable cloudfunctions.googleapis.com --project="$PROJECT_ID"
gcloud services enable cloudbuild.googleapis.com --project="$PROJECT_ID"

# Create Cloud Function to run audit
echo "Creating Cloud Function..."
cat > /tmp/main.py <<'EOF'
import subprocess
import os
from google.cloud import storage
import datetime

def run_audit(request):
    """Runs SA key audit and uploads results to GCS"""
    project_id = os.environ['PROJECT_ID']
    bucket_name = os.environ['BUCKET_NAME']
    
    # Run audit script
    result = subprocess.run(
        ['/bin/bash', 'audit_sa_keys.sh', project_id],
        capture_output=True,
        text=True
    )
    
    # Upload results to GCS
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    
    timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
    blob = bucket.blob(f'audits/sa_key_audit_{timestamp}.csv')
    blob.upload_from_filename(f'sa_key_audit_{timestamp}.csv')
    
    return {
        'status': 'success',
        'exit_code': result.returncode,
        'report_url': f'gs://{bucket_name}/audits/sa_key_audit_{timestamp}.csv'
    }
EOF

cat > /tmp/requirements.txt <<EOF
google-cloud-storage==2.10.0
EOF

# Create GCS bucket for audit reports
BUCKET_NAME="${PROJECT_ID}-sa-key-audits"
echo "Creating GCS bucket: $BUCKET_NAME"
gsutil mb -p "$PROJECT_ID" -l us-central1 "gs://$BUCKET_NAME" 2>/dev/null || echo "Bucket already exists"

# Deploy Cloud Function
echo "Deploying Cloud Function..."
gcloud functions deploy sa-key-audit \
    --project="$PROJECT_ID" \
    --runtime=python39 \
    --trigger-http \
    --entry-point=run_audit \
    --region=us-central1 \
    --set-env-vars="PROJECT_ID=$PROJECT_ID,BUCKET_NAME=$BUCKET_NAME" \
    --source=/tmp \
    --no-allow-unauthenticated

# Get function URL
FUNCTION_URL=$(gcloud functions describe sa-key-audit \
    --project="$PROJECT_ID" \
    --region=us-central1 \
    --format="value(httpsTrigger.url)")

# Create Cloud Scheduler job (runs every Monday at 9 AM)
echo "Creating Cloud Scheduler job..."
gcloud scheduler jobs create http sa-key-weekly-audit \
    --project="$PROJECT_ID" \
    --location=us-central1 \
    --schedule="0 9 * * 1" \
    --time-zone="America/New_York" \
    --uri="$FUNCTION_URL" \
    --http-method=POST \
    --oidc-service-account-email="$PROJECT_ID@appspot.gserviceaccount.com" \
    --description="Weekly service account key audit"

echo "✅ Cloud Scheduler setup complete!"
echo ""
echo "Audit reports will be saved to: gs://$BUCKET_NAME/audits/"
echo "Schedule: Every Monday at 9:00 AM EST"
echo ""
echo "To run audit manually:"
echo "  gcloud scheduler jobs run sa-key-weekly-audit --project=$PROJECT_ID --location=us-central1"
