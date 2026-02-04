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

output "constraint_names" {
  description = "Map of custom org policy constraint names"
  value = {
    log_error_verbosity     = google_org_policy_custom_constraint.alloydb_log_error_verbosity.name
    log_min_error_statement = google_org_policy_custom_constraint.alloydb_log_min_error_statement.name
    log_min_messages        = google_org_policy_custom_constraint.alloydb_log_min_messages.name
  }
}
