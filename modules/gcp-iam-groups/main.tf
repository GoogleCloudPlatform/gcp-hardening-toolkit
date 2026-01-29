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

data "google_organization" "org" {
  domain = var.domain
}

locals {
  groups_by_name = { for group in var.groups : group.display_name => group... }
  unique_groups  = { for name, groups in local.groups_by_name : name => groups[0] }
  group_names    = [for group in var.groups : group.display_name]
  group_roles = flatten([
    for group in var.groups : [
      for role in group.roles : {
        group_key = "${group.display_name}@${var.domain}"
        role      = role
        folder_id = group.folder_id
      }
    ]
  ])
}

resource "null_resource" "check_for_duplicates" {
  count = var.allow_multi_point_grants == false ? 1 : 0

  lifecycle {
    precondition {
      condition     = length(local.group_names) == length(distinct(local.group_names))
      error_message = "The 'groups' variable contains duplicated group names. Please ensure all 'display_name' values are unique."
    }
  }
}

resource "google_cloud_identity_group" "groups" {
  for_each = local.unique_groups

  display_name = each.value.display_name
  parent       = "customers/${var.customer_id}"

  group_key {
    id = "${each.value.display_name}@${var.domain}"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }

  description = each.value.description
}

resource "time_sleep" "wait_for_groups" {
  create_duration = "1m"

  triggers = {
    group_ids = join(",", values(google_cloud_identity_group.groups)[*].id)
  }
}

resource "google_organization_iam_member" "org_iam" {
  for_each = { for gr in local.group_roles : "${gr.group_key}-${gr.role}" => gr if gr.folder_id == null }

  org_id = replace(data.google_organization.org.id, "organizations/", "")
  role   = each.value.role
  member = "group:${each.value.group_key}"

  depends_on = [time_sleep.wait_for_groups]
}

resource "google_folder_iam_member" "folder_iam" {
  for_each = { for gr in local.group_roles : "${gr.group_key}-${gr.role}-${gr.folder_id}" => gr if gr.folder_id != null }

  folder = each.value.folder_id
  role   = each.value.role
  member = "group:${each.value.group_key}"

  depends_on = [time_sleep.wait_for_groups]
}
