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

resource "google_org_policy_custom_constraint" "instance_no_ip_forwarding" {
  name         = "custom.computeInstanceNoIPForwarding${random_string.constraint_suffix.result}"
  parent       = var.parent
  display_name = "Prevent IP forwarding on Compute Engine instances"
  description  = "This constraint ensures that IP forwarding is not enabled on Compute Engine instances."

  action_type = "DENY"

  condition = "resource.canIpForward == true"

  method_types = [
    "CREATE",
    "UPDATE"
  ]

  resource_types = [
    "compute.googleapis.com/Instance"
  ]
}

resource "time_sleep" "wait_for_constraint_creation" {
  create_duration = "5s"

  triggers = {
    constraint_name = google_org_policy_custom_constraint.instance_no_ip_forwarding.name
  }
}

resource "google_org_policy_policy" "enforce_instance_no_ip_forwarding" {
  name   = "${var.parent}/policies/${google_org_policy_custom_constraint.instance_no_ip_forwarding.name}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
  depends_on = [time_sleep.wait_for_constraint_creation]
}
