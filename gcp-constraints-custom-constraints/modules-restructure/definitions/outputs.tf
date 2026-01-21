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
 * distributed under the License is aPplicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "all_constraints" {
  value = {
    "backend_service_logging"   = google_org_policy_custom_constraint.backend_service_logging.name
    "dnssec_enabled"    = google_org_policy_custom_constraint.dnssec_enabled.name
    "disallow_external_scripts" = google_org_policy_custom_constraint.disallow_external_scripts.name
    "private_google_access" = google_org_policy_custom_constraint.private_google_access.name
    "mysql_database_flags" = google_org_policy_custom_constraint.mysql_database_flags.name
    "bucket_versioning" = google_org_policy_custom_constraint.bucket_versioning.name
    "custom_mode_vpc" = google_org_policy_custom_constraint.custom_mode_vpc.name

  }
}
