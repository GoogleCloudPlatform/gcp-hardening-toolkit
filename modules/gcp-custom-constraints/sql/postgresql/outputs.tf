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

output "custom_constraint_names" {
  description = "The names of the custom constraints created."
  value = [
    google_org_policy_custom_constraint.postgresql_log_connections.name,
    google_org_policy_custom_constraint.postgresql_log_disconnections.name,
    google_org_policy_custom_constraint.postgresql_log_error_verbosity.name,
    google_org_policy_custom_constraint.postgresql_log_min_duration_statement.name,
    google_org_policy_custom_constraint.postgresql_log_min_error_statement.name,
    google_org_policy_custom_constraint.postgresql_log_min_messages.name,
    google_org_policy_custom_constraint.postgresql_log_statement.name
  ]
}

output "org_policy_names" {
  description = "The names of the organization policies created."
  value       = [for p in google_org_policy_policy.postgresql_logging_policies : p.name]
}
