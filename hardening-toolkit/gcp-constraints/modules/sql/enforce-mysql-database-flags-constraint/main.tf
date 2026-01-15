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

resource "google_org_policy_custom_constraint" "mysql_database_flags" {
  name         = "custom.sqlMysqlDatabaseFlags${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce Cloud SQL for MySQL database flags"
  description  = "This custom constraint ensures that all Cloud SQL for MySQL instances have the 'skip_show_database' flag set to 'on' and the 'local_infile' flag set to 'off'."

  action_type = "DENY"

  condition = "resource.databaseVersion.startsWith('MYSQL_') && (!resource.settings.databaseFlags.exists(flag, flag.name == 'skip_show_database' && flag.value == 'on') || !resource.settings.databaseFlags.exists(flag, flag.name == 'local_infile' && flag.value == 'off'))"

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
    constraint_name = google_org_policy_custom_constraint.mysql_database_flags.name
  }
}

resource "google_org_policy_policy" "enforce_mysql_database_flags" {
  name   = "${var.parent}/policies/${google_org_policy_custom_constraint.mysql_database_flags.name}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [time_sleep.wait_for_constraint_creation]
}
