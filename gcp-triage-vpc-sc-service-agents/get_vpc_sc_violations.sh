# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#!/bin/bash

# Script to retrieve VPC-SC violations from a service perimeter in dry-run mode for the last 30 days.

# Usage: ./get_vpc_sc_violations.sh PERIMETER_ID

PERIMETER_ID=$1

if [ -z "$PERIMETER_ID" ]; then
  echo "Usage: ./get_vpc_sc_violations.sh PERIMETER_ID"
  exit 1
fi

# Get the full JSON description of the perimeter
PERIMETER_DESCRIPTION_JSON=$(gcloud access-context-manager perimeters describe "$PERIMETER_ID" --format=json)

# Extract project numbers from the JSON output, checking both spec.resources and status.resources
PROJECT_NUMBERS=$(echo "$PERIMETER_DESCRIPTION_JSON" | jq -r '(.spec.resources // .status.resources)[]' | sed 's/projects\///g')

if [ -z "$PROJECT_NUMBERS" ]; then
  echo "Could not find any projects in the perimeter '$PERIMETER_ID' or the perimeter description is empty."
  exit 1
fi

echo "Attempting to retrieve all logs from the last 30 days to check for any log visibility."

# Clear the violations file before starting
> vpc_sc_violations.jsonl

# Loop through each project number, get the project ID, and then get the logs
for project_number in $PROJECT_NUMBERS; do
  PROJECT_ID=$(gcloud projects describe "$project_number" --format="value(projectId)")
  echo "Retrieving all logs for project: $PROJECT_ID (Number: $project_number)"
  gcloud logging read "timestamp >= \"$(date -v -30d -u +'%Y-%m-%dT%H:%M:%SZ')\"" \
    --project="$PROJECT_ID" \
    --format=json | jq -c .[] >> vpc_sc_violations.jsonl
done

echo "Extracting unique principals to vpc_sc_violations_sa.txt"
jq -r '.protoPayload.authenticationInfo.principalEmail | select(. != null and contains("iam.gserviceaccount.com"))' vpc_sc_violations.jsonl | sort -u > vpc_sc_violations_sa.txt