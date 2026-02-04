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
    google_org_policy_custom_constraint.sqlserver_external_scripts_enabled.name,
    google_org_policy_custom_constraint.sqlserver_trace_flag_3625.name,
    google_org_policy_custom_constraint.sqlserver_contained_db_auth.name,
    google_org_policy_custom_constraint.sqlserver_cross_db_chaining.name,
    google_org_policy_custom_constraint.sqlserver_remote_access.name,
    google_org_policy_custom_constraint.sqlserver_user_connections.name,
    google_org_policy_custom_constraint.sqlserver_user_options.name
  ]
}

output "org_policy_names" {
  description = "The names of the organization policies created."
  value       = [for p in google_org_policy_policy.sqlserver_policies : p.name]
}
