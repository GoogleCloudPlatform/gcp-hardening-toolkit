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
