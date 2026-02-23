#!/bin/bash

# Define trusted domains here (space-separated or on new lines)
TRUSTED_DOMAINS=(
  "google.com"
)

# Define color codes for output
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if a project ID was provided as an argument.
if [ -z "$1" ]; then
  echo "Usage: $0 <project-id>"
  exit 1
fi

# Execute the gcloud command and capture its output
gcloud_output=$(gcloud projects describe "$1")

# Parse the output and set variables
createTime=$(echo "$gcloud_output" | grep "createTime:" | awk '{print $2}' | tr -d "'")
lifecycleState=$(echo "$gcloud_output" | grep "lifecycleState:" | awk '{print $2}')
name=$(echo "$gcloud_output" | grep "name:" | awk '{print $2}')
parent_id=$(echo "$gcloud_output" | grep "id:" | awk '{print $2}' | tr -d "'")
parent_type=$(echo "$gcloud_output" | grep "type:" | awk '{print $2}')
projectId=$(echo "$gcloud_output" | grep "projectId:" | awk '{print $2}')
projectNumber=$(echo "$gcloud_output" | grep "projectNumber:" | awk '{print $2}' | tr -d "'")

# Display Project Metadata
echo "========================================"
echo "Project Metadata:"
echo "========================================"
echo "createTime: $createTime"
echo "lifecycleState: $lifecycleState"
echo "name: $name"
echo "parent_id: $parent_id"
echo "parent_type: $parent_type"
echo "projectId: $projectId"
echo "projectNumber: $projectNumber"

# ==========================================
# Section 1: External / Untrusted Users
# ==========================================
echo ""
echo "========================================"
echo "IAM Assessment:"
echo "========================================"

all_users=$(gcloud asset search-all-iam-policies \
  --scope=projects/${projectId} \
  --format="value(policy.bindings.members.flatten())" | \
  tr ',' '\n' | tr ' ' '\n' | grep '^user:' | sed 's/^user://' | sort -u)

untrusted_users=""

# Check domains
for user in $all_users; do
  user_domain="${user#*@}"
  is_trusted=0

  if [ ${#TRUSTED_DOMAINS[@]} -gt 0 ]; then
    for trusted_domain in "${TRUSTED_DOMAINS[@]}"; do
      if [[ "$user_domain" == "$trusted_domain" ]]; then
        is_trusted=1
        break
      fi
    done
  fi

  if [ $is_trusted -eq 0 ]; then
    # Append the user to the list with a newline
    untrusted_users="$untrusted_users$user\n"
  fi
done

# Print users logic (highlighted in yellow if any are found)
if [ -n "$untrusted_users" ]; then
  echo -e "${YELLOW}External / Untrusted User Accounts Found:${NC}"
  echo -e "${YELLOW}$(echo -e "$untrusted_users" | sed '/^$/d' | sed 's/^/  - /')${NC}"
else
  echo "External / Untrusted User Accounts: None"
fi

# ==========================================
# Section 2: Network Assessment
# ==========================================
echo ""
echo "========================================"
echo "Network Assessment:"
echo "========================================"

# Default VPC Check
default_vpc=$(gcloud compute networks list --project="$projectId" --filter="name=default" --format="value(name)")

if [ "$default_vpc" == "default" ]; then
  echo -e "${YELLOW}Default VPC Found: true${NC}"
else
  echo "Default VPC Found: false"
fi

# Total VPC Count Check
vpc_count=$(gcloud compute networks list --project="$projectId" --format="value(name)" | wc -l | xargs)

if [ "$vpc_count" -gt 1 ]; then
  echo -e "${YELLOW}Total VPC Networks: $vpc_count${NC}"
else
  echo "Total VPC Networks: $vpc_count"
fi

# Firewall Rules Check (Open to the internet)
# Using JSON and jq to safely parse the nested objects.
# This completely bypasses the gcloud formatting bugs.
fw_allow_all_ips=$(gcloud compute firewall-rules list \
  --project="$projectId" \
  --filter="direction=INGRESS" \
  --format="json" 2>/dev/null | jq -r '
    .[]
    | select(.sourceRanges[]? == "0.0.0.0/0")
    | .allowed[]?
    | .IPProtocol as $proto
    | if .ports then (.ports[] | $proto + ":" + .) else $proto end
  ' | sort -u)

# Print open ports logic
if [ -n "$fw_allow_all_ips" ]; then
  echo -e "${YELLOW}Open to the internet (0.0.0.0/0):${NC}"
  echo -e "${YELLOW}$(echo "$fw_allow_all_ips" | sed '/^$/d' | sed 's/^/  - /')${NC}"
else
  echo "Open to the internet (0.0.0.0/0): None"
fi

echo "========================================"
