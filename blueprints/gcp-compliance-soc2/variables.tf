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

variable "project_id" {
  description = "The Google Cloud project ID to use for API calls."
  type        = string
}

variable "billing_project" {
  description = "The Google Cloud billing project ID to use for API calls."
  type        = string
}

variable "parent" {
  type        = string
  description = "The parent resource to attach the policy to. Must be in the format 'organizations/{organization_id}', 'folders/{folder_id}', or 'projects/{project_id}'."
}

variable "enable_sql_mysql_constraints" {
  type        = bool
  description = "Enable the SQL MySQL specific constraints for SOC2."
  default     = true
}

variable "enable_sql_postgresql_constraints" {
  type        = bool
  description = "Enable the SQL PostgreSQL specific constraints for SOC2."
  default     = true
}

variable "enable_sql_sqlserver_constraints" {
  type        = bool
  description = "Enable the SQL SQL Server specific constraints for SOC2."
  default     = true
}

variable "enable_alloydb_constraints" {
  type        = bool
  description = "Enable the AlloyDB constraints for SOC2."
  default     = true
}

variable "enable_dns_constraint" {
  type        = bool
  description = "Enable the DNSSEC custom constraint."
  default     = true
}

variable "enable_dns_policy_logging_constraint" {
  type        = bool
  description = "Enable the Cloud DNS Policy Logging custom constraint."
  default     = true
}

# BigQuery Constraints
variable "enable_bq_dataset_cmek_constraint" {

  type        = bool
  description = "Enable the BigQuery dataset default CMEK encryption constraint."
  default     = true
}

# Dataproc Constraints
variable "enable_dataproc_cmek_constraint" {
  type        = bool
  description = "Enable the Dataproc cluster CMEK encryption constraint."
  default     = true
}

variable "enable_instance_no_default_sa_constraint" {
  type        = bool
  description = "Enable the constraint preventing instances from using default service account."
  default     = true
}

variable "enable_instance_no_default_sa_full_scopes_constraint" {
  type        = bool
  description = "Enable the constraint preventing instances from using default service account with full scopes."
  default     = true
}

variable "enable_instance_no_ip_forwarding_constraint" {
  type        = bool
  description = "Enable the constraint preventing IP forwarding on instances."
  default     = true
}

# DNS Constraints
variable "enable_dnssec_no_rsasha1_constraint" {
  type        = bool
  description = "Enable the constraint preventing use of RSASHA1 algorithm for DNSSEC."
  default     = true
}

# Built-in Organization Policies
variable "enable_soc2_org_policies" {
  type        = bool
  description = "Enable the built-in organization policies for SOC2 compliance."
  default     = true
}

variable "parent_folder" {
  type        = string
  description = "The folder ID where policies will be applied. Leave empty if using organization_id."
  default     = ""
}

variable "domains_to_allow" {
  type        = list(string)
  description = "List of domains allowed for IAM policy members."
  default     = []
}

variable "allowed_resource_locations" {
  type        = list(string)
  description = "List of allowed resource locations for data residency."
  default     = ["us-east4", "us-central1"]
}

variable "trusted_image_projects" {
  type        = list(string)
  description = "List of allowed trusted image projects for VM instances."
  default     = []
}

variable "essential_contacts_domains_to_allow" {
  type        = list(string)
  description = "List of allowed domains for essential contacts."
  default     = []
}

variable "denied_non_cmek_services" {
  type        = list(string)
  description = "List of services to restrict from using non-CMEK encryption. Example: ['storage.googleapis.com', 'bigquery.googleapis.com']."
  default     = ["storage.googleapis.com", "bigquery.googleapis.com", "compute.googleapis.com", "sqladmin.googleapis.com"]
}

variable "log_project_id" {
  description = "The ID of the project where the BigQuery dataset will be created."
  type        = string
  default     = null
}
