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

resource "google_org_policy_policy" "enforce_constraints" {
  # Terraform now knows the keys (k) statically from your variables!
  for_each = {
    for k, v in var.enforcement_toggles : k => v
    if v == true
  }

  # Use the key to find the randomized ID in the second map
  name   = "${var.parent}/policies/${var.all_constraint_names[each.key]}"
  parent = var.parent

  spec {
    rules {
      enforce = true
    }
  }
# Add this block to handle API race conditions
  lifecycle {
    create_before_destroy = true
  }
}
