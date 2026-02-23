#!/bin/bash

echo "============================================================"
echo "         GCP Project Security Triage and Enumeration        "
echo "============================================================"
echo ""
echo "This script performs a rapid security assessment of a GCP project."
echo "It covers project metadata, IAM policies, network configurations,"
echo "and Cloud DNS settings (Private DNS & DNSSEC)."
echo ""

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
# Section 1: IAM Assessment
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

# Privileged Roles Check (Owner/Editor)
privileged_accounts=$(gcloud asset search-all-iam-policies \
  --scope=projects/${projectId} \
  --format="json" 2>/dev/null | jq -r '
    .[]
    | .policy.bindings[]
    | select(.role == "roles/owner" or .role == "roles/editor")
    | .members[]
  ' | sort -u)

if [ -n "$privileged_accounts" ]; then
  echo -e "${YELLOW}Privileged Accounts (Owner/Editor) Found:${NC}"
  echo -e "${YELLOW}$(echo "$privileged_accounts" | sed '/^$/d' | sed 's/^/  - /')${NC}"
else
  echo "Privileged Accounts (Owner/Editor): None"
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

# ==========================================
# Section 3: Cloud DNS Assessment
# ==========================================
echo ""
echo "========================================"
echo "Cloud DNS Assessment:"
echo "========================================"

# Get all networks
networks=$(gcloud compute networks list --project="$projectId" --format="value(name)")

# Get all private managed zones and their details (including networks and DNSSEC state)
# We use 'json' format and jq to parse it reliably.
private_managed_zones_json=$(gcloud dns managed-zones list --project="$projectId" --filter="visibility=private" --format="json" 2>/dev/null)

echo "Checking Private DNS activation for each VPC network:"
echo "Private DNS Enabled:"
for network in $networks; do
  network_url="https://www.googleapis.com/compute/v1/projects/$projectId/global/networks/$network"
  is_private_dns_enabled="DISABLED"

  # Check if this network is associated with any private managed zone
  if echo "$private_managed_zones_json" | jq -e '.[] | select(.privateVisibilityConfig.networks[]?.networkUrl == "'"$network_url"'")' &>/dev/null; then
    is_private_dns_enabled="ENABLED"
  fi

  if [ "$is_private_dns_enabled" = "ENABLED" ]; then
    echo "  - $network: ENABLED"
  else
    echo -e "${YELLOW}  - $network: DISABLED${NC}"
  fi
done

echo ""
echo "Checking DNSSEC activation for each VPC network:"
echo "DNSSEC Enabled:"
for network in $networks; do
  network_url="https://www.googleapis.com/compute/v1/projects/$projectId/global/networks/$network"
  dnssec_status="DISABLED"

  # Check if any private managed zone associated with this network has DNSSEC enabled
  if echo "$private_managed_zones_json" | jq -e '.[] | select(.privateVisibilityConfig.networks[]?.networkUrl == "'"$network_url"'") | select(.dnssecConfig.state == "on" or .dnssecConfig.state == "transfer")' &>/dev/null; then
    dnssec_status="ENABLED"
  fi

  if [ "$dnssec_status" = "ENABLED" ]; then
    echo "  - $network: ENABLED"
  else
    echo -e "${YELLOW}  - $network: DISABLED${NC}"
  fi
done

# ==========================================
# Section 4: Service Account Key Assessment
# ==========================================
echo ""
echo "========================================"
echo "Service Account Key Assessment:"
echo "========================================"

all_sa_keys=""
service_accounts=$(gcloud iam service-accounts list --project="$projectId" --format="value(email)")

for sa in $service_accounts; do
  keys=$(gcloud iam service-accounts keys list --iam-account="$sa" --project="$projectId" --format="value(name)")
  if [ -n "$keys" ]; then
    for key in $keys; do
      all_sa_keys="$all_sa_keys$sa - $key\n"
    done
  fi
done

if [ -n "$all_sa_keys" ]; then
  echo -e "${YELLOW}Service Account Keys Found:${NC}"
  echo -e "${YELLOW}$(echo -e "$all_sa_keys" | sed '/^$/d' | sed 's/^/  - /')${NC}"
else
  echo "Service Account Keys: None"
fi

echo ""
echo "============================================================"
echo "         GCP Project Security Triage - Scan Complete        "
echo "============================================================"
echo ""
echo "Important findings and potential issues are highlighted in yellow."
echo "Review the output above for a comprehensive security overview."
echo ""
