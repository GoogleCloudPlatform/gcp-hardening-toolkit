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

# -------------------------------------------------------
# VPC Service Controls
# -------------------------------------------------------
resource "google_access_context_manager_access_policy" "access_policy" {
  parent = "organizations/${var.organization_id}"
  title  = var.policy_name
}

# -------------------------------------------------------
# Logic to Combine File and Dynamic Accounts
# -------------------------------------------------------
locals {
  # (Keep your existing logic for reading the file and projects)
  static_members_raw = try(split("\n", file("${path.module}/authorized_sa_list.txt")), [])

  static_members = [
    for line in local.static_members_raw :
    startswith(trimspace(line), "serviceAccount:") ? trimspace(line) : "serviceAccount:${trimspace(line)}"
    if trimspace(line) != ""
  ]

  dynamic_members = [
    "serviceAccount:service-${google_project.project_1.number}@gs-project-accounts.iam.gserviceaccount.com"
  ]

  # This is the Master List of "Safe" Agents
  final_access_list = concat(local.static_members, local.dynamic_members)
}

# -------------------------------------------------------
# Perimeter Configuration
# -------------------------------------------------------
resource "google_access_context_manager_service_perimeter" "perimeter" {
  parent                    = "accessPolicies/${google_access_context_manager_access_policy.access_policy.name}"
  name                      = "accessPolicies/${google_access_context_manager_access_policy.access_policy.name}/servicePerimeters/${var.perimeter_name}"
  title                     = var.perimeter_name
  use_explicit_dry_run_spec = true

  spec {
    resources = [
      "projects/${google_project.project_1.number}",
      "projects/${google_project.project_2.number}",
    ]

    restricted_services = [
      "storage.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
      "bigquery.googleapis.com",
      "pubsub.googleapis.com",
      "logging.googleapis.com",
      "monitoring.googleapis.com"
    ]

    # -------------------------------------------------------
    # 1. INGRESS POLICY
    # -------------------------------------------------------
    ingress_policies {
      ingress_from {
        # FIX: We ONLY provide the list.
        # We REMOVED 'identity_type' to avoid the conflict.
        identities = local.final_access_list
      }

      ingress_to {
        resources = ["*"]
        operations {
          service_name = "*"
        }
      }
    }

    # -------------------------------------------------------
    # 2. EGRESS POLICY
    # -------------------------------------------------------
    egress_policies {
      egress_from {
        # FIX: Same here. Remove identity_type.
        identities = local.final_access_list
      }

      egress_to {
        resources = ["*"]
        operations {
          service_name = "*"
        }
      }
    }
  }
}
