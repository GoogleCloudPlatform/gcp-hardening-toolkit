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

resource "google_org_policy_custom_constraint" "postgresql_log_connections" {
  name         = "custom.postgresqlLogConnections${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_connections flag for PostgreSQL instances"
  description  = "Ensures log_connections is set to 'on'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('POSTGRES') && !resource.settings.databaseFlags.exists(f, f.name == 'log_connections' && f.value == 'on')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "postgresql_log_disconnections" {
  name         = "custom.postgresqlLogDisconnections${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_disconnections flag for PostgreSQL instances"
  description  = "Ensures log_disconnections is set to 'on'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('POSTGRES') && !resource.settings.databaseFlags.exists(f, f.name == 'log_disconnections' && f.value == 'on')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "postgresql_log_error_verbosity" {
  name         = "custom.postgresqlLogErrorVerbosity${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_error_verbosity flag for PostgreSQL instances"
  description  = "Ensures log_error_verbosity is set to 'default'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('POSTGRES') && resource.settings.databaseFlags.exists(f, f.name == 'log_error_verbosity' && f.value != 'default')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "postgresql_log_min_duration_statement" {
  name         = "custom.postgresqlLogMinDurationStatement${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_min_duration_statement flag for PostgreSQL instances"
  description  = "Ensures log_min_duration_statement is set to '-1' (disabled)."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('POSTGRES') && resource.settings.databaseFlags.exists(f, f.name == 'log_min_duration_statement' && f.value != '-1')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "postgresql_log_min_error_statement" {
  name         = "custom.postgresqlLogMinErrorStatement${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_min_error_statement flag for PostgreSQL instances"
  description  = "Ensures log_min_error_statement is set to 'error'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('POSTGRES') && !resource.settings.databaseFlags.exists(f, f.name == 'log_min_error_statement' && f.value == 'error')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "postgresql_log_min_messages" {
  name         = "custom.postgresqlLogMinMessages${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_min_messages flag for PostgreSQL instances"
  description  = "Ensures log_min_messages is set to 'warning'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('POSTGRES') && !resource.settings.databaseFlags.exists(f, f.name == 'log_min_messages' && f.value == 'warning')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "postgresql_log_statement" {
  name         = "custom.postgresqlLogStatement${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce log_statement flag for PostgreSQL instances"
  description  = "Ensures log_statement is set to 'ddl'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('POSTGRES') && !resource.settings.databaseFlags.exists(f, f.name == 'log_statement' && f.value == 'ddl')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "time_sleep" "wait_for_postgresql_constraints" {
  create_duration = "5s"
  triggers = {
    c1 = google_org_policy_custom_constraint.postgresql_log_connections.name
    c2 = google_org_policy_custom_constraint.postgresql_log_disconnections.name
    c3 = google_org_policy_custom_constraint.postgresql_log_error_verbosity.name
    c4 = google_org_policy_custom_constraint.postgresql_log_min_duration_statement.name
    c5 = google_org_policy_custom_constraint.postgresql_log_min_error_statement.name
    c6 = google_org_policy_custom_constraint.postgresql_log_min_messages.name
    c7 = google_org_policy_custom_constraint.postgresql_log_statement.name
  }
}

# Policies
resource "google_org_policy_policy" "postgresql_logging_policies" {
  for_each = {
    postgresqlLogConnections           = google_org_policy_custom_constraint.postgresql_log_connections.name
    postgresqlLogDisconnections        = google_org_policy_custom_constraint.postgresql_log_disconnections.name
    postgresqlLogErrorVerbosity        = google_org_policy_custom_constraint.postgresql_log_error_verbosity.name
    postgresqlLogMinDurationStatement  = google_org_policy_custom_constraint.postgresql_log_min_duration_statement.name
    postgresqlLogMinErrorStatement     = google_org_policy_custom_constraint.postgresql_log_min_error_statement.name
    postgresqlLogMinMessages           = google_org_policy_custom_constraint.postgresql_log_min_messages.name
    postgresqlLogStatement            = google_org_policy_custom_constraint.postgresql_log_statement.name
  }
  name   = "${var.parent}/policies/${each.value}"
  parent = var.parent
  spec {
    rules {
      enforce = true
    }
  }
  depends_on = [time_sleep.wait_for_postgresql_constraints]
}
