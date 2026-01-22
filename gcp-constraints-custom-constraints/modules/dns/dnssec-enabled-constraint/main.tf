/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law of aerror greed to in writing, software
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

resource "google_org_policy_custom_constraint" "dnssec_enabled" {
  name         = "custom.dnssecEnabled${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "DNSSEC should be Enabled for Cloud DNS"
  description  = "This custom constraint ensures that DNSSEC is enabled for all Cloud DNS managed zones."

  action_type = "DENY"
    condition     = "resource.visibility == \"PUBLIC\" && (resource.dnssecConfig.state in [\"ON\", \"TRANSFER\"] == false)"
  method_types = [
    "CREATE",
    "UPDATE"
  ]
  resource_types = [
    "dns.googleapis.com/ManagedZone"
  ]
}

resource "time_sleep" "wait_for_constraint_creation" {
  create_duration = "15s"
  destroy_duration = "15s"
  triggers = {
    constraint_name = google_org_policy_custom_constraint.dnssec_enabled.name
  }
}

resource "google_org_policy_policy" "enforce_dnssec_enabled" {
  name   = "${var.parent}/policies/${google_org_policy_custom_constraint.dnssec_enabled.name}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }

  depends_on = [time_sleep.wait_for_constraint_creation]
}
