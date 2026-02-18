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

resource "google_org_policy_custom_constraint" "alloydb_log_error_verbosity" {
  name         = "custom.alloydbLogErrorVerbosity${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_error_verbosity flag for AlloyDB instances"
  description  = "Ensures log_error_verbosity is set to 'default'."
  action_type  = "DENY"
  condition    = "resource.databaseFlags.exists(key, key == 'log_error_verbosity') && resource.databaseFlags['log_error_verbosity'] != 'default'"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["alloydb.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "alloydb_log_min_error_statement" {
  name         = "custom.alloydbLogMinErrorStatement${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_min_error_statement flag for AlloyDB instances"
  description  = "Ensures log_min_error_statement is set to 'error'."
  action_type  = "DENY"
  condition    = "!(resource.databaseFlags.exists(key, key == 'log_min_error_statement') && resource.databaseFlags['log_min_error_statement'] == 'error')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["alloydb.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "alloydb_log_min_messages" {
  name         = "custom.alloydbLogMinMessages${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_min_messages flag for AlloyDB instances"
  description  = "Ensures log_min_messages is set to 'warning'."
  action_type  = "DENY"
  condition    = "!(resource.databaseFlags.exists(key, key == 'log_min_messages') && resource.databaseFlags['log_min_messages'] == 'warning')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["alloydb.googleapis.com/Instance"]
}

resource "time_sleep" "wait_for_constraint_creation" {
  create_duration = "5s"

  triggers = {
    constraint_name_1 = google_org_policy_custom_constraint.alloydb_log_error_verbosity.name
    constraint_name_2 = google_org_policy_custom_constraint.alloydb_log_min_error_statement.name
    constraint_name_3 = google_org_policy_custom_constraint.alloydb_log_min_messages.name
  }
}

resource "google_org_policy_policy" "enforce_alloydb_logging_constraints" {
  for_each = {
    log_error_verbosity     = google_org_policy_custom_constraint.alloydb_log_error_verbosity.name
    log_min_error_statement = google_org_policy_custom_constraint.alloydb_log_min_error_statement.name
    log_min_messages       = google_org_policy_custom_constraint.alloydb_log_min_messages.name
  }
  name   = "${var.parent}/policies/${each.value}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [time_sleep.wait_for_constraint_creation]
}
