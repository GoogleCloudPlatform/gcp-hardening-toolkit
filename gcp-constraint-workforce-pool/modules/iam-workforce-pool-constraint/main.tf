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

# Resource to generate a random, 6-character hex string.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Define the custom organization policy constraint
resource "google_org_policy_custom_constraint" "lock_workforce_pools" {
  name           = "custom.${var.constraint_base_name}${random_string.suffix.result}"
  parent         = "organizations/${var.organization_id}"
  display_name   = var.display_name
  description    = var.description
  action_type    = "DENY"

  resource_types = [
    "iam.googleapis.com/AllowPolicy"
  ]

  method_types = [
    "CREATE",
    "UPDATE",
  ]

  condition = format(
    "resource.bindings.exists(binding, !RoleNameStartsWith(binding.role, [%s]) && binding.members.exists(member, MemberTypeMatches(member, ['iam.googleapis.com/WorkforcePoolPrincipal', 'iam.googleapis.com/WorkforcePoolPrincipalSet'])))",
    join(", ", [for r in var.allowed_roles_prefixes : "'${r}'"])
  )
}

# Enforce the custom organization policy
resource "google_org_policy_policy" "enforce_lock_workforce_pools" {
  name   = "${google_org_policy_custom_constraint.lock_workforce_pools.parent}/policies/${google_org_policy_custom_constraint.lock_workforce_pools.name}"
  parent = "organizations/${var.organization_id}"

  spec {
    rules {
      enforce = true
    }
  }
}
