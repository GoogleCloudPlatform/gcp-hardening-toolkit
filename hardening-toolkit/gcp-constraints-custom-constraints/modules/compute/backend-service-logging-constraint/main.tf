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

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "google_org_policy_custom_constraint" "enforce_backend_service_logging" {
  name         = "custom.computeBackendServiceLogging${random_string.suffix.result}"
  parent       = var.parent
  display_name = "Enforce Backend Service Logging"
  description  = "This custom constraint ensures that all Backend Services have logging enabled."

  action_type = "DENY"

  condition = "has(resource.logConfig) == false || resource.logConfig.enable == false"

  method_types = [
    "CREATE",
    "UPDATE"
  ]

  resource_types = [
    "compute.googleapis.com/BackendService"
  ]
}

resource "time_sleep" "wait_for_constraint_creation" {
  create_duration = "15s"
  destroy_duration = "15s"

  triggers = {
    constraint_name = google_org_policy_custom_constraint.enforce_backend_service_logging.name
  }
}

resource "google_org_policy_policy" "enforce_backend_service_logging" {
  name   = "${var.parent}/policies/${google_org_policy_custom_constraint.enforce_backend_service_logging.name}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [time_sleep.wait_for_constraint_creation]
}