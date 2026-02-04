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

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.45.2"
    }
  }
}

provider "google" {
  user_project_override = true
  billing_project       = var.billing_project
  project               = var.project_id
}

module "sql_mysql_constraints" {
  count  = var.enable_sql_mysql_constraints ? 1 : 0
  source = "../../modules/gcp-custom-constraints/sql/mysql"
  parent = var.parent
}

module "sql_postgresql_constraints" {
  count  = var.enable_sql_postgresql_constraints ? 1 : 0
  source = "../../modules/gcp-custom-constraints/sql/postgresql"
  parent = var.parent
}

module "sql_sqlserver_constraints" {
  count  = var.enable_sql_sqlserver_constraints ? 1 : 0
  source = "../../modules/gcp-custom-constraints/sql/sqlserver"
  parent = var.parent
}

module "alloydb_private_ip_constraints" {
  count  = var.enable_alloydb_constraints ? 1 : 0
  source = "../../modules/gcp-custom-constraints/alloydb/private-ip-constraint"
  parent = var.parent
}

module "alloydb_logging_constraints" {
  count  = var.enable_alloydb_constraints ? 1 : 0
  source = "../../modules/gcp-custom-constraints/alloydb/logging-constraints"
  parent = var.parent
}

module "dns_dnssec_enabled_constraint" {
  count = var.enable_dns_constraint ? 1 : 0
  source = "../../modules/gcp-custom-constraints/dns/dnssec-enabled-constraint"
  parent = var.parent
}

module "dns_policy_logging_constraint" {
  count = var.enable_dns_policy_logging_constraint ? 1 : 0
  source = "../../modules/gcp-custom-constraints/dns/dns-policy-logging-constraint"
  parent = var.parent
}
