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

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "google_org_policy_custom_constraint" "backend_service_logging" {
  name         = "custom.computeBackendServiceLogging${random_string.suffix.result}"
  parent       = var.parent
  display_name = "Create Backend Service Logging"
  description  = "This custom constraint ensures that all Backend Services have logging enabled."

  action_type = "DENY"

  condition = "has(resource.logConfig) == false || resource.logConfig.enable == false"

  method_types = [
    "CREATE",
    "UPDATE"
  ]

  resource_types = [
    "compute.googleapis.com/BackendService"
  ]
}

resource "google_org_policy_custom_constraint" "dnssec_enabled" {
  name         = "custom.dnssecEnabled${random_string.suffix.result}"
  parent       = var.parent
  display_name = "DNSSEC should be Enabled for Cloud DNS"
  description  = "This custom constraint ensures that DNSSEC is enabled for all Cloud DNS managed zones."

  action_type = "DENY"
    condition     = "resource.visibility == \"PUBLIC\" && (resource.dnssecConfig.state in [\"ON\", \"TRANSFER\"] == false)"
  method_types = [
    "CREATE",
    "UPDATE"
  ]
  resource_types = [
    "dns.googleapis.com/ManagedZone"
  ]
}

resource "google_org_policy_custom_constraint" "disallow_external_scripts" {
  name         = "custom.sqlDisallowExternalScriptsv1${random_string.suffix.result}"
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

resource "google_org_policy_custom_constraint" "mysql_database_flags" {
  name         = "custom.sqlMysqlDatabaseFlagsv1${random_string.suffix.result}"
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

resource "google_org_policy_custom_constraint" "bucket_versioning" {
  name         = "custom.storageBucketVersioning${random_string.suffix.result}"
  parent       = var.parent
  display_name = "Enforce Cloud Storage bucket object versioning"
  description  = "This constraint ensures that all Cloud Storage buckets have object versioning enabled."

  action_type = "ALLOW"

  condition = "resource.versioning.enabled == true"

  method_types = [
    "CREATE",
    "UPDATE"
  ]

  resource_types = [
    "storage.googleapis.com/Bucket"
  ]
}

resource "google_org_policy_custom_constraint" "custom_mode_vpc" {
  name         = "custom.computeCustomModeVPC${random_string.suffix.result}"
  parent       = var.parent
  display_name = "Enforce custom mode VPC networks"
  description  = "This custom constraint ensures that all VPC networks are created in custom mode."

  action_type = "DENY"

  condition = "resource.autoCreateSubnetworks == true"

  method_types = [
    "CREATE"
  ]

  resource_types = [
    "compute.googleapis.com/Network"
  ]
}

resource "google_org_policy_custom_constraint" "private_google_access" {
  name         = "custom.computePrivateGoogleAccess${random_string.suffix.result}"
  parent       = var.parent
  display_name = "Enforce private Google access on subnets"
  description  = "This custom constraint ensures that all subnets have private Google access enabled."

  action_type = "ALLOW"

  condition = "resource.privateIpGoogleAccess == true"

  method_types = [
    "CREATE",
    "UPDATE"
  ]

  resource_types = [
    "compute.googleapis.com/Subnetwork"
  ]
}
