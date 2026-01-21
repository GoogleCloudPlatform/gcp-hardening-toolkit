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

provider "google" {
  # This tells Terraform which project pays for the Org Policy API calls
  user_project_override = true
  billing_project       = "seed-prj-470417"
}
module "definitions" {
  source = "./definitions"
  parent = var.parent
}

resource "time_sleep" "wait_for_propagation" {
  create_duration  = "120s"
  destroy_duration = "120s"
  depends_on       = [module.definitions]
}

module "enforcement" {
  source = "./enforcement"
  parent = var.parent

# STATIC KEYS: Known during the 'plan' phase to prevent for_each errors.
  enforcement_toggles = {
    "mysql_database_flags"              = var.enable_sql_flags
    "disallow_external_scripts"         = var.enable_sql_external_scripts
    "custom_mode_vpc"                   = var.enable_vpc_custom_mode
    "private_google_access"             = var.enable_vpc_google_access
    "dnssec_enabled"                    = var.enable_dns_dnssec
    "bucket_versioning"                 = var.enable_gcs_versioning
    "backend_service_logging"           = var.enable_backend_logging
  }

  # DYNAMIC VALUES: The randomized IDs passed from the definition outputs.
  all_constraint_names = module.definitions.all_constraints

  # Ensure the 60s sleep finishes before enforcement starts
  depends_on = [time_sleep.wait_for_propagation]
}
