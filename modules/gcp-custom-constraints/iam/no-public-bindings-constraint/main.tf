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

resource "random_string" "constraint_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_org_policy_custom_constraint" "iam_no_public_bindings" {
  name         = "custom.iamNoPublicBindings${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Prevent public IAM bindings (allUsers, allAuthenticatedUsers)"
  description  = "This constraint prevents the use of allUsers and allAuthenticatedUsers in IAM allow policies across the organization."

  action_type = "DENY"

  condition = "resource.bindings.exists(binding, binding.members.exists(member, MemberSubjectMatches(member, ['allUsers', 'allAuthenticatedUsers'])))"

  method_types = [
    "CREATE",
    "UPDATE"
  ]

  resource_types = [
    "iam.googleapis.com/AllowPolicy"
  ]
}

resource "time_sleep" "wait_for_constraint_creation" {
  create_duration = "5s"

  triggers = {
    constraint_name = google_org_policy_custom_constraint.iam_no_public_bindings.name
  }
}

resource "google_org_policy_policy" "enforce_iam_no_public_bindings" {
  name   = "${var.parent}/policies/${google_org_policy_custom_constraint.iam_no_public_bindings.name}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [time_sleep.wait_for_constraint_creation]
}
