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

# Print users logic (highlighted if any are found)
if [ -n "$untrusted_users" ]; then
  echo "External / Untrusted User Accounts Found:"
  echo -e "$(echo -e "$untrusted_users" | sed '/^$/d' | sed 's/^/  - /')"
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
  echo "Privileged Accounts (Owner/Editor) Found:"
  echo "$(echo "$privileged_accounts" | sed '/^$/d' | sed 's/^/  - /')"
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
  echo "Default VPC Found: true"
else
  echo "Default VPC Found: false"
fi

# Total VPC Count Check
vpc_count=$(gcloud compute networks list --project="$projectId" --format="value(name)" | wc -l | xargs)

if [ "$vpc_count" -gt 1 ]; then
  echo "Total VPC Networks: $vpc_count"
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
  echo "Open to the internet (0.0.0.0/0):"
  echo "$(echo "$fw_allow_all_ips" | sed '/^$/d' | sed 's/^/  - /')"
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
    echo "  - $network: DISABLED"
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
    echo "  - $network: DISABLED"
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
  echo "Service Account Keys Found:"
  echo -e "$(echo -e "$all_sa_keys" | sed '/^$/d' | sed 's/^/  - /')"
else
  echo "Service Account Keys: None"
fi

# ==========================================
# Section 5: Public Resource Exposure
# ==========================================
echo ""
echo "========================================"
echo "Public Resource Exposure:"
echo "========================================"

# Public GCS Buckets
echo "Public GCS Buckets (allUsers / allAuthenticatedUsers):"
public_buckets=$(gcloud asset search-all-iam-policies \
  --scope=projects/${projectId} \
  --asset-types=storage.googleapis.com/Bucket \
  --query="policy:(allUsers OR allAuthenticatedUsers)" \
  --format="value(resource)" 2>/dev/null)

if [ -n "$public_buckets" ]; then
  echo "$public_buckets" | sed 's/^/  - /'
else
  echo "  - None"
fi

# Public BigQuery Datasets
echo "Public BigQuery Datasets (allUsers / allAuthenticatedUsers):"
public_bq=$(gcloud asset search-all-iam-policies \
  --scope=projects/${projectId} \
  --asset-types=bigquery.googleapis.com/Dataset \
  --query="policy:(allUsers OR allAuthenticatedUsers)" \
  --format="value(resource)" 2>/dev/null)

if [ -n "$public_bq" ]; then
  echo "$public_bq" | sed 's/^/  - /'
else
  echo "  - None"
fi

# ==========================================
# Section 6: Infrastructure Exposure
# ==========================================
echo ""
echo "========================================"
echo "Infrastructure Exposure:"
echo "========================================"

# Compute Instances with External IPs
echo "Compute Instances with External IPs:"
instances_ext_ip=$(gcloud compute instances list --project="$projectId" \
  --format="table[no-heading](name, networkInterfaces[].accessConfigs[0].natIP)" | grep -v "None" | awk '{print $1 " (" $2 ")"}')

if [ -n "$instances_ext_ip" ]; then
  echo "$instances_ext_ip" | sed 's/^/  - /'
else
  echo "  - None"
fi

# Cloud SQL Public IPs
echo "Cloud SQL Instances with Public IP Enabled:"
sql_public_ips=$(gcloud sql instances list --project="$projectId" \
  --format="value(name)" --filter="settings.ipConfiguration.ipv4Enabled=true")

if [ -n "$sql_public_ips" ]; then
  echo "$sql_public_ips" | sed 's/^/  - /'
else
  echo "  - None"
fi

# ==========================================
# Section 7: Service Account Hardening
# ==========================================
echo ""
echo "========================================"
echo "Service Account Hardening:"
echo "========================================"

# Default Service Account Usage (Compute)
echo "Compute Instances using Default Service Account:"
default_sa_instances=$(gcloud compute instances list --project="$projectId" \
  --format="value(name)" --filter="serviceAccounts.email ~ .*compute@developer.gserviceaccount.com")

if [ -n "$default_sa_instances" ]; then
  echo "$default_sa_instances" | sed 's/^/  - /'
else
  echo "  - None"
fi

# Old Service Account Keys (Older than 90 days)
echo "Service Account Keys older than 90 days:"
current_date_sec=$(date +%s)
ninety_days_sec=$((90 * 24 * 60 * 60))

# Get all keys and their creation dates
all_keys_info=$(gcloud iam service-accounts list --project="$projectId" --format="value(email)" | while read sa; do
  gcloud iam service-accounts keys list --iam-account="$sa" --project="$projectId" --format="value(name,validAfterTime)"
done)

found_old_keys=0
while read -r key_name key_date; do
  if [ -n "$key_name" ] && [ -n "$key_date" ]; then
    # Parse ISO 8601 date to seconds (requires GNU date or compatible)
    key_date_sec=$(date -d "$key_date" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$key_date" +%s 2>/dev/null)
    if [ -n "$key_date_sec" ]; then
      age_sec=$((current_date_sec - key_date_sec))
      if [ "$age_sec" -gt "$ninety_days_sec" ]; then
        echo "  - $key_name (Created: $key_date)"
        found_old_keys=1
      fi
    fi
  fi
done <<< "$all_keys_info"

if [ "$found_old_keys" -eq 0 ]; then
  echo "  - None"
fi

# ==========================================
# Section 8: Serverless & Artifact Exposure
# ==========================================
echo ""
echo "========================================"
echo "Serverless & Artifact Exposure:"
echo "========================================"

# Public Cloud Run Services
echo "Public Cloud Run Services (Unauthenticated Access):"
public_run=$(gcloud asset search-all-iam-policies \
  --scope=projects/${projectId} \
  --asset-types=run.googleapis.com/Service \
  --query="policy:(allUsers OR allAuthenticatedUsers)" \
  --format="value(resource)" 2>/dev/null)

if [ -n "$public_run" ]; then
  echo "$public_run" | sed 's/^/  - /'
else
  echo "  - None"
fi

# Public Cloud Functions
echo "Public Cloud Functions (Unauthenticated Access):"
public_functions=$(gcloud asset search-all-iam-policies \
  --scope=projects/${projectId} \
  --asset-types=cloudfunctions.googleapis.com/Function \
  --query="policy:(allUsers OR allAuthenticatedUsers)" \
  --format="value(resource)" 2>/dev/null)

if [ -n "$public_functions" ]; then
  echo "$public_functions" | sed 's/^/  - /'
else
  echo "  - None"
fi

# Public Artifact Registry Repositories
echo "Public Artifact Registry Repositories:"
public_ar=$(gcloud asset search-all-iam-policies \
  --scope=projects/${projectId} \
  --asset-types=artifactregistry.googleapis.com/Repository \
  --query="policy:(allUsers OR allAuthenticatedUsers)" \
  --format="value(resource)" 2>/dev/null)

if [ -n "$public_ar" ]; then
  echo "$public_ar" | sed 's/^/  - /'
else
  echo "  - None"
fi

# ==========================================
# Section 9: Network Visibility (Flow Logs)
# ==========================================
echo ""
echo "========================================"
echo "Network Visibility (Flow Logs):"
echo "========================================"

# Checking Flow Logs for all subnets
echo "VPC Subnets with Flow Logs DISABLED:"
disabled_flow_logs=$(gcloud compute networks subnets list --project="$projectId" \
  --format="value(name,region,network)" --filter="logConfig.enable=false OR logConfig.enable:null")

if [ -n "$disabled_flow_logs" ]; then
  echo "$disabled_flow_logs" | while read -r name region network; do
    echo "  - $name ($region) in VPC: $network"
  done
else
  echo "  - All subnets have Flow Logs enabled."
fi

# ==========================================
# Section 10: VM-Level Hardening
# ==========================================
echo ""
echo "========================================"
echo "VM-Level Hardening:"
echo "========================================"

# Project-wide SSH Keys Check
echo "Project-wide SSH Keys Enabled:"
block_project_ssh=$(gcloud compute project-info describe --project="$projectId" \
  --format="json" | jq -r '.commonInstanceMetadata.items[]? | select(.key=="block-project-ssh-keys") | .value' 2>/dev/null)

if [ "$block_project_ssh" == "true" ]; then
  echo "  - Status: DISABLED (Hardened)"
else
  echo "  - Status: ENABLED (Risk: Project-level keys can access all VMs)"
fi

# Serial Port Access Check
echo "Instances with Serial Port Access ENABLED:"
serial_port_instances=$(gcloud compute instances list --project="$projectId" \
  --format="json" 2>/dev/null | jq -r '
    .[]
    | select(.metadata.items[]? | select(.key == "serial-port-enable" and (.value == "true" or .value == "1")))
    | .name
  ')

if [ -n "$serial_port_instances" ]; then
  echo "$serial_port_instances" | sed 's/^/  - /'
else
  echo "  - None"
fi

echo ""
echo "============================================================"
echo "         GCP Project Security Triage - Scan Complete        "
echo "============================================================"
echo ""
echo "Review the output above for a comprehensive security overview."
echo ""
