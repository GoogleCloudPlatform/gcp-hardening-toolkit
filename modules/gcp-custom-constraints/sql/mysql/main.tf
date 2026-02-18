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

resource "google_org_policy_custom_constraint" "mysql_skip_show_database" {
  name         = "custom.mysqlSkipShowDatabase${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce skip_show_database flag for MySQL instances"
  description  = "This constraint ensures that Cloud SQL MySQL instances have the 'skip_show_database' flag set to 'on'."

  action_type = "DENY"

  condition = "resource.databaseVersion.startsWith('MYSQL') && !resource.settings.databaseFlags.exists(f, f.name == 'skip_show_database' && f.value == 'on')"

  method_types   = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "time_sleep" "wait_for_mysql_constraint" {
  create_duration = "5s"
  triggers = {
    constraint_name = google_org_policy_custom_constraint.mysql_skip_show_database.name
  }
}

resource "google_org_policy_policy" "mysql_skip_show_database" {
  name   = "${var.parent}/policies/${google_org_policy_custom_constraint.mysql_skip_show_database.name}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [time_sleep.wait_for_mysql_constraint]
}
