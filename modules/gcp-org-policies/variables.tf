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

# This file contains the variable definitions for the gcp-foundation-org-policies module.

variable "organization_id" {
  type        = string
  description = "The organization ID where the policies will be applied."
}

variable "parent_folder" {
  type        = string
  description = "The folder ID where the policies will be applied."
  default     = ""
}

variable "create_access_context_manager_access_policy" {
  type        = bool
  description = "Create an access context manager access policy."
  default     = false
}

variable "domains_to_allow" {
  type        = list(string)
  description = "The list of domains (IDs) to allow for domain restricted sharing (constraints/iam.allowedPolicyMemberDomains). This constraint requires at least one domain."
  default     = []
}

variable "allowed_external_ips" {
  type        = list(string)
  description = "The list of allowed external IPs for VM instances."
  default     = []
}

variable "essential_contacts_domains_to_allow" {
  type        = list(string)
  description = "The list of allowed domains for essential contacts."
  default     = []
}

variable "allowed_resource_locations" {
  type        = list(string)
  description = "The list of allowed resource locations."
  default     = ["us-east4", "us-central1"]
}

variable "trusted_image_projects" {
  type        = list(string)
  description = "The list of allowed trusted image projects."
  default     = []
}

variable "allowed_non_confidential_computing" {
  type        = list(string)
  description = "List of VM types allowed without confidential computing. Empty list means all VMs must use confidential computing."
  default     = []
}

variable "denied_non_cmek_services" {
  type        = list(string)
  description = "List of services to restrict from using non-CMEK encryption (constraints/gcp.restrictNonCmekServices). Example: ['storage.googleapis.com', 'bigquery.googleapis.com']."
  default     = []
}

variable "allowed_vpc_flow_logs_settings" {
  type        = list(string)
  description = "List of allowed VPC Flow Logs settings. Use predefined values: 'ESSENTIAL' (10-50% sampling), 'LIGHT' (50-100% sampling), 'COMPREHENSIVE' (100% sampling). Empty list enforces VPC Flow Logs with no specific sampling rate requirement."
  default     = ["ESSENTIAL", "LIGHT", "COMPREHENSIVE"]
}
