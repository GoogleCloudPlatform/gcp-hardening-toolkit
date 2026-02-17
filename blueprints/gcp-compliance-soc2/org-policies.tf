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

# Built-in Organization Policies for SOC2 Compliance
# This module enforces the following GCP built-in organization policy constraints:
# - compute.requireVpcFlowLogs
# - storage.uniformBucketLevelAccess
# - sql.restrictPublicIp
# - storage.publicAccessPrevention
# - compute.restrictNonConfidentialComputing
# - compute.skipDefaultNetworkCreation
# - gcp.restrictNonCmekServices
# - compute.requireOsLogin
# - compute.disableSerialPortAccess
# - compute.vmExternalIpAccess

module "soc2_org_policies" {
  count  = var.enable_soc2_org_policies ? 1 : 0
  source = "../../modules/gcp-org-policies"

  # Extract numeric organization ID from parent (e.g., "organizations/858770860297" -> "858770860297")
  organization_id = split("/", var.parent)[0] == "organizations" ? split("/", var.parent)[1] : ""
  parent_folder   = split("/", var.parent)[0] == "folders" ? var.parent : ""

  # Allow all VPC Flow Logs sampling rates
  allowed_vpc_flow_logs_settings = ["ESSENTIAL", "LIGHT", "COMPREHENSIVE"]

  # Deny all external IPs by default
  allowed_external_ips = []

  # Require confidential computing for all VMs
  allowed_non_confidential_computing = []

  # CMEK services hardening - restricts non-CMEK encryption for specific services
  denied_non_cmek_services = var.denied_non_cmek_services

  # Domain restrictions - must provide at least one domain (constraint doesn't support deny all)
  # Update this with your organization's domain in terraform.tfvars
  domains_to_allow = var.domains_to_allow

  # Resource location restrictions
  allowed_resource_locations = var.allowed_resource_locations

  # Trusted image projects
  trusted_image_projects = var.trusted_image_projects

  # Essential contacts domains
  essential_contacts_domains_to_allow = var.essential_contacts_domains_to_allow
}
