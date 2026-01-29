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

# This file is the main entrypoint for the gcp-foundation-org-policies module.

module "org_policies" {
  source = "../../modules/gcp-org-policies"

  organization_id = var.organization_id
  parent_folder   = var.parent_folder

  domains_to_allow                    = var.domains_to_allow
  allowed_external_ips                = var.allowed_external_ips
  essential_contacts_domains_to_allow = var.essential_contacts_domains_to_allow
  allowed_resource_locations          = var.allowed_resource_locations
  trusted_image_projects              = var.trusted_image_projects
}

resource "google_access_context_manager_access_policy" "access_policy" {
  count  = var.create_access_context_manager_access_policy ? 1 : 0
  parent = "organizations/${var.organization_id}"
  title  = "default policy"
}
