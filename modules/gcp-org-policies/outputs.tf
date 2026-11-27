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

# This file contains the output definitions for the gcp-foundation-org-policies module.

output "enforced_boolean_policies" {
  description = "Boolean constraints enforced by this module."
  value       = sort(tolist(local.selected_boolean_policies))

  # Fail at plan time on unknown names, so a typo cannot silently skip a control.
  precondition {
    condition     = length(setsubtract(local.selected_boolean_policies, local.boolean_type_organization_policies)) == 0
    error_message = "Unsupported value(s) in boolean_policies: ${join(", ", sort(tolist(setsubtract(local.selected_boolean_policies, local.boolean_type_organization_policies))))}. See README.md for the supported constraints."
  }
}

output "enforced_list_policies" {
  description = "List constraints enforced by this module. iam.allowedPolicyMemberDomains is only enforced when domains_to_allow is not empty."
  value       = [for policy in sort(tolist(local.selected_list_policies)) : policy if policy != "iam.allowedPolicyMemberDomains" || length(var.domains_to_allow) > 0]

  precondition {
    condition     = length(setsubtract(local.selected_list_policies, local.list_type_organization_policies)) == 0
    error_message = "Unsupported value(s) in list_policies: ${join(", ", sort(tolist(setsubtract(local.selected_list_policies, local.list_type_organization_policies))))}. See README.md for the supported constraints."
  }
}
