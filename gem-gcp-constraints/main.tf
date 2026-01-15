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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11.1"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}
provider "google" {
  project               = var.project_id
  user_project_override = true
  billing_project       = var.billing_project
}
module "dnssec_enabled_constraint" {

  count  = var.enable_dns_constraint ? 1 : 0

  source = "./modules/dns/dnssec-enabled-constraint"

  parent = var.parent

}


module "disallow_external_scripts_constraint" {

  count  = var.enable_sql_constraint ? 1 : 0
  source = "./modules/sql/disallow-external-scripts-constraint"
  parent = var.parent
}



module "enforce_bucket_versioning_constraint" {

  count  = var.enable_storage_constraint ? 1 : 0

  source = "./modules/storage/enforce-bucket-versioning-constraint"

  parent = var.parent

}



module "enforce_private_google_access_constraint" {

  count  = var.enable_vpc_private_google_access_constraint ? 1 : 0

  source = "./modules/vpc/enforce-private-google-access-constraint"

  parent = var.parent

}

module "enforce_custom_mode_vpc_constraint" {

  count  = var.enable_vpc_custom_mode_constraint ? 1 : 0
  
  source = "./modules/vpc/enforce-custom-mode-vpc-constraint"
  
  parent = var.parent

}

module "enforce_backend_service_logging_constraint" {

  count  = var.enable_compute_backend_service_logging_constraint ? 1 : 0

  source = "./modules/compute/enforce-backend-service-logging-constraint"

  parent = var.parent

}



module "enforce_mysql_database_flags_constraint" {

  count  = var.enable_sql_mysql_database_flags_constraint ? 1 : 0

  source = "./modules/sql/enforce-mysql-database-flags-constraint"

  parent = var.parent

}

