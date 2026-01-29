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

variable "impersonate_service_account_email" {
  description = "Service account email to impersonate for all Google provider calls (e.g., tf-admin@org-ops.iam.gserviceaccount.com)."
  type        = string
}


provider "google" {
  impersonate_service_account = var.impersonate_service_account_email
  request_timeout             = "60s"
}
