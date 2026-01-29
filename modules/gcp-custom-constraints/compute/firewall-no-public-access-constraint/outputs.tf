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

output "custom_constraint_name" {
  description = "The name of the custom constraint for firewall no public access"
  value       = google_org_policy_custom_constraint.firewall_no_public_access.name
}

output "policy_name" {
  description = "The name of the organization policy enforcing this constraint"
  value       = google_org_policy_policy.enforce_firewall_no_public_access.name
}
