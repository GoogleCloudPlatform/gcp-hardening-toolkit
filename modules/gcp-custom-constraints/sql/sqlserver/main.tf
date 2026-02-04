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

resource "google_org_policy_custom_constraint" "sqlserver_external_scripts_enabled" {
  name         = "custom.sqlserverExternalScriptsEnabled${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Disable external scripts for SQL Server"
  description  = "Ensures 'external scripts enabled' is set to 'off'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('SQLSERVER') && resource.settings.databaseFlags.exists(f, f.name == 'external scripts enabled' && f.value == 'on')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "sqlserver_trace_flag_3625" {
  name         = "custom.sqlserverTraceFlag3625${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enable Trace Flag 3625 for SQL Server"
  description  = "Ensures '3625 (trace flag)' is set to 'on'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('SQLSERVER') && !resource.settings.databaseFlags.exists(f, f.name == '3625' && f.value == 'on')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "sqlserver_contained_db_auth" {
  name         = "custom.sqlserverContainedDbAuth${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Disable contained database authentication for SQL Server"
  description  = "Ensures 'contained database authentication' is set to 'off'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('SQLSERVER') && resource.settings.databaseFlags.exists(f, f.name == 'contained database authentication' && f.value == 'on')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "sqlserver_cross_db_chaining" {
  name         = "custom.sqlserverCrossDbChaining${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Disable cross db ownership chaining for SQL Server"
  description  = "Ensures 'cross db ownership chaining' is set to 'off'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('SQLSERVER') && resource.settings.databaseFlags.exists(f, f.name == 'cross db ownership chaining' && f.value == 'on')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "sqlserver_remote_access" {
  name         = "custom.sqlserverRemoteAccess${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Disable remote access for SQL Server"
  description  = "Ensures 'remote access' is set to 'off'."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('SQLSERVER') && !resource.settings.databaseFlags.exists(f, f.name == 'remote access' && f.value == 'off')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "sqlserver_user_connections" {
  name         = "custom.sqlserverUserConnections${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Restrict user connections for SQL Server"
  description  = "Ensures 'user connections' is set to '0' (none/default)."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('SQLSERVER') && resource.settings.databaseFlags.exists(f, f.name == 'user connections' && f.value != '0')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "google_org_policy_custom_constraint" "sqlserver_user_options" {
  name         = "custom.sqlserverUserOptions${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Restrict user options for SQL Server"
  description  = "Ensures 'user options' is set to 'none' (or empty)."
  action_type  = "DENY"
  condition    = "resource.databaseVersion.startsWith('SQLSERVER') && resource.settings.databaseFlags.exists(f, f.name == 'user options' && f.value != 'none' && f.value != '0')"
  method_types = ["CREATE", "UPDATE"]
  resource_types = ["sqladmin.googleapis.com/Instance"]
}

resource "time_sleep" "wait_for_sqlserver_constraints" {
  create_duration = "5s"
  triggers = {
    c1 = google_org_policy_custom_constraint.sqlserver_external_scripts_enabled.name
    c2 = google_org_policy_custom_constraint.sqlserver_trace_flag_3625.name
    c3 = google_org_policy_custom_constraint.sqlserver_contained_db_auth.name
    c4 = google_org_policy_custom_constraint.sqlserver_cross_db_chaining.name
    c5 = google_org_policy_custom_constraint.sqlserver_remote_access.name
    c6 = google_org_policy_custom_constraint.sqlserver_user_connections.name
    c7 = google_org_policy_custom_constraint.sqlserver_user_options.name
  }
}

# Policies
resource "google_org_policy_policy" "sqlserver_policies" {
  for_each = {
    sqlserverExternalScriptsEnabled = google_org_policy_custom_constraint.sqlserver_external_scripts_enabled.name
    sqlserverTraceFlag3625          = google_org_policy_custom_constraint.sqlserver_trace_flag_3625.name
    sqlserverContainedDbAuth        = google_org_policy_custom_constraint.sqlserver_contained_db_auth.name
    sqlserverCrossDbChaining        = google_org_policy_custom_constraint.sqlserver_cross_db_chaining.name
    sqlserverRemoteAccess           = google_org_policy_custom_constraint.sqlserver_remote_access.name
    sqlserverUserConnections        = google_org_policy_custom_constraint.sqlserver_user_connections.name
    sqlserverUserOptions            = google_org_policy_custom_constraint.sqlserver_user_options.name
  }
  name   = "${var.parent}/policies/${each.value}"
  parent = var.parent
  spec {
    rules {
      enforce = true
    }
  }
  depends_on = [time_sleep.wait_for_sqlserver_constraints]
}
