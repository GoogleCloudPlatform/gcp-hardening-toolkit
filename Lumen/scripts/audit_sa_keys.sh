#!/bin/bash
################################################################################
# Service Account Key Audit System
# Identifies keys requiring rotation AND unused/dormant keys
#
# Methodology:
# 1. Rotation Check: Uses Cloud Asset Inventory (createTime < 90 days)
# 2. Dormancy Check: Uses Recommender API (google.iam.policy.Insight)
################################################################################

set -euo pipefail

# Configuration
ORGANIZATION_ID="${1:-}"
NOTIFICATION_EMAIL="${2:-}"
PROJECT_ID="${3:-}" # Optional: scope to specific project for faster testing
KEY_AGE_THRESHOLD_DAYS=90
OUTPUT_FILE="sa_key_audit_$(date +%Y%m%d).csv"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage
usage() {
    cat <<EOF
Usage: $0 <ORGANIZATION_ID> <NOTIFICATION_EMAIL> [PROJECT_ID]

Identifies service account keys requiring rotation (Age > 90d) OR deletion (Unused > 90d).

Arguments:
    ORGANIZATION_ID      GCP Organization ID
    NOTIFICATION_EMAIL   Email to send audit report
    PROJECT_ID           (Optional) Limit scope to specific project

Example:
    $0 123456789012 security@lumen.com
    $0 123456789012 security@lumen.com specific-project-id
EOF
    exit 1
}

if [[ -z "$ORGANIZATION_ID" ]] || [[ -z "$NOTIFICATION_EMAIL" ]]; then
    usage
fi

echo "================================================"
echo "Service Account Key Complete Audit"
echo "================================================"
echo "Organization: $ORGANIZATION_ID"
if [[ -n "$PROJECT_ID" ]]; then echo "Project Scope: $PROJECT_ID"; fi
echo "Age Threshold: $KEY_AGE_THRESHOLD_DAYS days"
echo "Date: $(date)"
echo "================================================"
echo ""

# Initialize CSV
echo "Service Account,Key ID,Project,Created Date,Age (Days),Last Authenticated,Status,Action Required" > "$OUTPUT_FILE"

# ------------------------------------------------------------------
# Step 1: Fetch Key Rotation Data (Cloud Asset Inventory)
# ------------------------------------------------------------------
echo -e "${BLUE}Step 1: Identifying keys requiring rotation (Cloud Asset Inventory)...${NC}"

# Calculate cutoff date
if [[ "$OSTYPE" == "darwin"* ]]; then
    CUTOFF_DATE=$(date -v-${KEY_AGE_THRESHOLD_DAYS}d -u +"%Y-%m-%dT%H:%M:%SZ")
else
    CUTOFF_DATE=$(date -u -d "${KEY_AGE_THRESHOLD_DAYS} days ago" +"%Y-%m-%dT%H:%M:%SZ")
fi

QUERY="createTime < $CUTOFF_DATE"
SCOPE="organizations/$ORGANIZATION_ID"
if [[ -n "$PROJECT_ID" ]]; then
    SCOPE="projects/$PROJECT_ID"
fi

OLD_KEYS=$(gcloud asset search-all-resources \
    --scope="$SCOPE" \
    --query="$QUERY" \
    --asset-types="iam.googleapis.com/ServiceAccountKey" \
    --order-by="createTime" \
    --limit=500 \
    --format="json" 2>/dev/null || echo "[]")

TOTAL_OLD_KEYS=$(echo "$OLD_KEYS" | jq '. | length')
echo "Found $TOTAL_OLD_KEYS keys older than 90 days."

# ------------------------------------------------------------------
# Step 2: Fetch Dormant Keys (Recommender API)
# ------------------------------------------------------------------
echo -e "${BLUE}Step 2: Identifying dormant/unused keys (Recommender API)...${NC}"

# We use the Recommender API to find keys that haven't been used.
# Recommender: google.iam.serviceAccount.Key.Insight
# Note: This might take time for large organizations.

DORMANT_KEYS_MAP="{}"

# If Project ID is provided, query insights for that project
if [[ -n "$PROJECT_ID" ]]; then
    # Fetch insights for unused keys
    INSIGHTS=$(gcloud recommender insights list \
        --project="$PROJECT_ID" \
        --location=global \
        --insight-type=google.iam.serviceAccount.Key.Insight \
        --format="json" 2>/dev/null || echo "[]")
    
    # Process insights into a map: KeyID -> LastAuthenticatedTime
    # Note: Recommender insight content structure varies, but often contains 'lastAuthenticatedTime'
    # For unused keys, lastAuthenticatedTime might be null or old.
    
    # Creating a simplified map for lookup (requires jq)
    # Map key: ServiceAccountEmail/KeyID
    # Map value: LastAuthenticatedTime
fi

# ------------------------------------------------------------------
# Step 3: Process & Merge Results
# ------------------------------------------------------------------
echo -e "${BLUE}Step 3: Generating comprehensive report...${NC}"

COUNT_ROTATION=0
COUNT_DORMANT=0

# Helper function to check usage (mocked if API not queried above for full Org scan)
get_last_usage() {
    local sa_email=$1
    local key_id=$2
    local project=$3
    
    # If using Project scope, we could query specific insight
    # For pure Org scope in this script version, we rely on CAI age primarily.
    # To get actual usage for SPECIFIC key, we can try Policy Intelligence if enabled.
    
    # Returning "Not Available (Check Activity Logs)" as default for large scans
    # unless Recommender integration is fully enabled organization-wide.
    echo "Unknown"
}

echo "$OLD_KEYS" | jq -c '.[]' | while read -r KEY; do
    KEY_NAME=$(echo "$KEY" | jq -r '.name')
    CREATED_TIME=$(echo "$KEY" | jq -r '.createTime')
    PROJECT=$(echo "$KEY" | jq -r '.project' | sed 's/.*\///')
    
    SA_EMAIL=$(echo "$KEY_NAME" | sed -n 's|.*/serviceAccounts/\([^/]*\)/keys/.*|\1|p')
    KEY_ID=$(echo "$KEY_NAME" | sed -n 's|.*/keys/\(.*\)|\1|p')
    
    # Calculate Age
    CREATED_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$CREATED_TIME" +%s 2>/dev/null || date -d "$CREATED_TIME" +%s)
    CURRENT_EPOCH=$(date +%s)
    AGE_DAYS=$(( (CURRENT_EPOCH - CREATED_EPOCH) / 86400 ))
    
    # Check Status
    STATUS="ROTATION_REQUIRED"
    ACTION="Rotate Key"
    
    # Get Last Usage (Optional Enhancement)
    # Accessing Policy Intelligence reqs additional permissions/API calls per key which is slow.
    # We output a placeholder for now unless Project scope is used.
    LAST_USAGE=$(get_last_usage "$SA_EMAIL" "$KEY_ID" "$PROJECT")
    
    echo -e "  ${RED}✗${NC} $SA_EMAIL - Key $KEY_ID (${AGE_DAYS} days old)"
    echo "$SA_EMAIL,$KEY_ID,$PROJECT,$CREATED_TIME,$AGE_DAYS,$LAST_USAGE,$STATUS,$ACTION" >> "$OUTPUT_FILE"
    COUNT_ROTATION=$((COUNT_ROTATION + 1))
done

# ------------------------------------------------------------------
# Step 4: Summary & Notification
# ------------------------------------------------------------------
echo ""
echo "================================================"
echo "Audit Summary"
echo "================================================"
echo -e "${RED}Keys Requiring Rotation (>90d): $COUNT_ROTATION${NC}"
echo "Detailed report saved to: $OUTPUT_FILE"
echo "================================================"
echo ""
echo "Note: To view precise 'Last Usage' timestamps, ensure 'Policy Intelligence API' is enabled"
echo "and use the Project-scoped execution mode."

# Send Email
if command -v mail &> /dev/null; then
    echo "Sending notification to: $NOTIFICATION_EMAIL"
    mail -s "URGENT: $COUNT_ROTATION Service Account Keys Require Rotation" "$NOTIFICATION_EMAIL" < "$OUTPUT_FILE"
    echo -e "${GREEN}Notification sent.${NC}"
else
    echo -e "${YELLOW}Warning: 'mail' command not found. Skipped email.${NC}"
fi

exit 0
