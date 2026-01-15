/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
################################################################################
# SOC2 Confidentiality Controls (C1.1-C1.2)
# Protects confidential information through encryption and access controls
################################################################################

# C1.1: Enforce uniform bucket-level access for Cloud Storage
resource "google_org_policy_policy" "uniform_bucket_access" {
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/storage.uniformBucketLevelAccess", null) == null ? 1 : 0

  name   = "${var.parent}/policies/storage.uniformBucketLevelAccess"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# C1.1: Prevent public access to Cloud Storage buckets
resource "google_org_policy_policy" "prevent_public_buckets" {
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/storage.publicAccessPrevention", null) == null ? 1 : 0

  name   = "${var.parent}/policies/storage.publicAccessPrevention"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
}

# C1.1: Require CMEK (Customer-Managed Encryption Keys) for services
# This is a LIST constraint that specifies which services require CMEK
resource "google_org_policy_policy" "require_cmek" {
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/gcp.restrictNonCmekServices", null) == null ? 1 : 0

  name   = "${var.parent}/policies/gcp.restrictNonCmekServices"
  parent = var.parent

  spec {
    rules {
      # Deny these services from creating resources without CMEK
      values {
        denied_values = [
          "storage.googleapis.com",
          "bigquery.googleapis.com",
          "compute.googleapis.com",
          "sqladmin.googleapis.com"
        ]
      }
    }
  }
}

# C1.2: Restrict VPC peering to prevent data exfiltration
resource "google_org_policy_policy" "restrict_vpc_peering" {
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/compute.restrictVpcPeering", null) == null ? 1 : 0

  name   = "${var.parent}/policies/compute.restrictVpcPeering"
  parent = var.parent

  spec {
    rules {
      deny_all = true
    }
  }
}