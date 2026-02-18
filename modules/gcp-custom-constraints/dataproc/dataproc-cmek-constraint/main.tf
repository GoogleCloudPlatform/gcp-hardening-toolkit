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

resource "random_string" "constraint_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_org_policy_custom_constraint" "dataproc_cmek" {
  name         = "custom.dataprocClusterCMEK${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Enforce CMEK encryption on Dataproc cluster persistent disks"
  description  = "This constraint ensures that all Dataproc clusters use Customer-Managed Encryption Keys (CMEK) for persistent disk encryption."

  action_type = "ALLOW"

  condition = "has(resource.config.encryptionConfig) && resource.config.encryptionConfig.gcePdKmsKeyName.startsWith(\"projects/\")"

  method_types = [
    "CREATE",
    "UPDATE"
  ]

  resource_types = [
    "dataproc.googleapis.com/Cluster"
  ]
}

resource "time_sleep" "wait_for_constraint_creation" {
  create_duration = "5s"

  triggers = {
    constraint_name = google_org_policy_custom_constraint.dataproc_cmek.name
  }
}

resource "google_org_policy_policy" "enforce_dataproc_cmek" {
  name   = "${var.parent}/policies/${google_org_policy_custom_constraint.dataproc_cmek.name}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
  depends_on = [time_sleep.wait_for_constraint_creation]
}
