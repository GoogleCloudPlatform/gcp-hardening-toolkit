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
# SOC2 Availability Controls (A1.1-A1.3)
# Ensures system availability through backup policies and resource location restrictions
################################################################################

# A1.3: Restrict resource locations to approved regions
resource "google_org_policy_policy" "restrict_resource_locations" {
  # Only create if the module is enabled and the policy doesn't already exist.
  count = var.enabled && lookup(var.existing_policies, "constraints/gcp.resourceLocations", null) == null ? 1 : 0

  name   = "${var.parent}/policies/gcp.resourceLocations"
  parent = var.parent

  spec {
    rules {
      values {
        allowed_values = [for region in var.allowed_regions : "in:${region}-locations"]
      }
    }
  }
}