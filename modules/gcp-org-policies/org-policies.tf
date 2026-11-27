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
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.45.2"
    }
  }
}

locals {
  organization_id = var.parent_folder != "" ? null : var.organization_id
  folder_id       = var.parent_folder != "" ? var.parent_folder : null
  policy_for      = var.parent_folder != "" ? "folder" : "organization"

  boolean_type_organization_policies = toset([
    "compute.disableNestedVirtualization",
    "compute.disableVpcExternalIpv6",
    "compute.setNewProjectDefaultToZonalDNSOnly",
    "compute.disableSerialPortAccess",
    "compute.skipDefaultNetworkCreation",
    "compute.restrictXpnProjectLienRemoval",
    "compute.requireOsLogin",
    "sql.restrictPublicIp",
    "sql.restrictAuthorizedNetworks",
    "iam.disableServiceAccountKeyCreation",
    "iam.automaticIamGrantsForDefaultServiceAccounts",
    "iam.disableServiceAccountKeyUpload",
    "storage.uniformBucketLevelAccess",
    "storage.publicAccessPrevention",
    "compute.requireShieldedVm"
  ])

  # Supported list constraints. Each one is enforced by a dedicated module block below.
  list_type_organization_policies = toset([
    "compute.vmExternalIpAccess",
    "compute.restrictProtocolForwardingCreationForTypes",
    "iam.allowedPolicyMemberDomains",
    "compute.trustedImageProjects",
    "essentialcontacts.allowedContactDomains",
    "gcp.resourceLocations",
    "compute.restrictNonConfidentialComputing",
    "gcp.restrictNonCmekServices",
    "compute.requireVpcFlowLogs"
  ])

  # Policies selected by the caller. null (default) enforces every supported policy,
  # which keeps the behavior of existing callers unchanged.
  selected_boolean_policies = var.boolean_policies == null ? local.boolean_type_organization_policies : toset(var.boolean_policies)
  selected_list_policies    = var.list_policies == null ? local.list_type_organization_policies : toset(var.list_policies)
}

module "organization_policies_type_boolean" {
  source   = "terraform-google-modules/org-policy/google"
  version  = "~> 7.0"
  for_each = local.selected_boolean_policies

  organization_id = local.organization_id
  folder_id       = local.folder_id
  policy_for      = local.policy_for
  policy_type     = "boolean"
  enforce         = "true"
  constraint      = "constraints/${each.value}"
}

# /******************************************
#   Compute org policies
# *******************************************/

module "org_vm_external_ip_access" {
  count   = contains(local.selected_list_policies, "compute.vmExternalIpAccess") ? 1 : 0
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 7.0"

  organization_id = local.organization_id
  folder_id       = local.folder_id
  policy_for      = local.policy_for
  policy_type     = "list"
  enforce         = "true"
  # enforce = true overrides the allow list below
  allow             = var.allowed_external_ips
  allow_list_length = length(var.allowed_external_ips)
  constraint        = "constraints/compute.vmExternalIpAccess"
}

module "restrict_protocol_fowarding" {
  count   = contains(local.selected_list_policies, "compute.restrictProtocolForwardingCreationForTypes") ? 1 : 0
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 7.0"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow             = ["INTERNAL"]
  allow_list_length = 1
  constraint        = "constraints/compute.restrictProtocolForwardingCreationForTypes"
}

# /******************************************
#   IAM
# *******************************************/

module "org_domain_restricted_sharing" {
  count   = contains(local.selected_list_policies, "iam.allowedPolicyMemberDomains") && length(var.domains_to_allow) > 0 ? 1 : 0
  source  = "terraform-google-modules/org-policy/google//modules/domain_restricted_sharing"
  version = "~> 7.0"

  organization_id  = local.organization_id
  folder_id        = local.folder_id
  policy_for       = local.policy_for
  domains_to_allow = var.domains_to_allow
}

# /******************************************
#   Compute org policies
# *******************************************/

module "org_trusted_image_projects" {
  count   = contains(local.selected_list_policies, "compute.trustedImageProjects") ? 1 : 0
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 7.0"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow             = var.trusted_image_projects
  allow_list_length = length(var.trusted_image_projects)
  constraint        = "constraints/compute.trustedImageProjects"
}

# /******************************************
#   Restrict contact domains
# *******************************************/

module "restrict_contact_domains" {
  count   = contains(local.selected_list_policies, "essentialcontacts.allowedContactDomains") ? 1 : 0
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 7.1"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow             = var.essential_contacts_domains_to_allow
  allow_list_length = length(var.essential_contacts_domains_to_allow)
  constraint        = "constraints/essentialcontacts.allowedContactDomains"
}

/******************************************
  Resource Location Restriction
*******************************************/

module "resource_location_restriction" {
  count   = contains(local.selected_list_policies, "gcp.resourceLocations") ? 1 : 0
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 7.4.0"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow             = var.allowed_resource_locations
  allow_list_length = length(var.allowed_resource_locations)
  constraint        = "constraints/gcp.resourceLocations"
}

/******************************************
  Restrict Non-Confidential Computing
*******************************************/

module "restrict_non_confidential_computing" {
  count   = contains(local.selected_list_policies, "compute.restrictNonConfidentialComputing") ? 1 : 0
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 7.4.0"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow             = var.allowed_non_confidential_computing
  allow_list_length = length(var.allowed_non_confidential_computing)
  constraint        = "constraints/compute.restrictNonConfidentialComputing"
}

/******************************************
  Restrict Non-CMEK Services
*******************************************/

module "restrict_non_cmek_services" {
  count   = contains(local.selected_list_policies, "gcp.restrictNonCmekServices") ? 1 : 0
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 7.4.0"

  organization_id  = local.organization_id
  folder_id        = local.folder_id
  policy_for       = local.policy_for
  policy_type      = "list"
  deny             = var.denied_non_cmek_services
  deny_list_length = length(var.denied_non_cmek_services)
  constraint       = "constraints/gcp.restrictNonCmekServices"
}

/******************************************
  Require VPC Flow Logs
*******************************************/

module "require_vpc_flow_logs" {
  count   = contains(local.selected_list_policies, "compute.requireVpcFlowLogs") ? 1 : 0
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 7.4.0"

  organization_id   = local.organization_id
  folder_id         = local.folder_id
  policy_for        = local.policy_for
  policy_type       = "list"
  allow             = var.allowed_vpc_flow_logs_settings
  allow_list_length = length(var.allowed_vpc_flow_logs_settings)
  constraint        = "constraints/compute.requireVpcFlowLogs"
}

/******************************************
  State migration
*******************************************/

# These module blocks gained a `count` meta-argument so they can be selected
# through var.list_policies. The moved blocks map their previous addresses to
# the new ones, so existing deployments keep their policies instead of
# destroying and recreating them. org_domain_restricted_sharing already used
# `count`, so its address did not change.

moved {
  from = module.org_vm_external_ip_access
  to   = module.org_vm_external_ip_access[0]
}

moved {
  from = module.restrict_protocol_fowarding
  to   = module.restrict_protocol_fowarding[0]
}

moved {
  from = module.org_trusted_image_projects
  to   = module.org_trusted_image_projects[0]
}

moved {
  from = module.restrict_contact_domains
  to   = module.restrict_contact_domains[0]
}

moved {
  from = module.resource_location_restriction
  to   = module.resource_location_restriction[0]
}

moved {
  from = module.restrict_non_confidential_computing
  to   = module.restrict_non_confidential_computing[0]
}

moved {
  from = module.restrict_non_cmek_services
  to   = module.restrict_non_cmek_services[0]
}

moved {
  from = module.require_vpc_flow_logs
  to   = module.require_vpc_flow_logs[0]
}
