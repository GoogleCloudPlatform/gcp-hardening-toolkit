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

resource "google_org_policy_custom_constraint" "disallow_external_scripts" {
  name         = "custom.sqlDisallowExternalScripts${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Disallow 'external scripts enabled' flag on Cloud SQL for SQL Server"
  description  = "This custom constraint ensures that the 'external scripts enabled' flag is set to 'off' for all Cloud SQL for SQL Server instances."

  action_type = "ALLOW"
  condition   = "!resource.databaseVersion.startsWith('SQLSERVER_') || resource.settings.databaseFlags.all(flag, flag.name != 'external scripts enabled' || flag.value == 'off')"
  method_types = [
    "CREATE",
    "UPDATE"
  ]
  resource_types = [
    "sqladmin.googleapis.com/Instance"
  ]
}

resource "time_sleep" "wait_for_constraint_creation" {
  create_duration = "5s"

  triggers = {
    constraint_name = google_org_policy_custom_constraint.disallow_external_scripts.name
  }
}

resource "google_org_policy_policy" "enforce_disallow_external_scripts" {
  name   = "${var.parent}/policies/${google_org_policy_custom_constraint.disallow_external_scripts.name}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [time_sleep.wait_for_constraint_creation]
}
