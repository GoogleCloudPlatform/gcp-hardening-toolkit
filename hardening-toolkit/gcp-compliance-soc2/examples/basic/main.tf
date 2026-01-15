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
module "soc2_compliance" {
  source = "../../"

  organization_id  = "<YOUR_ORGANIZATION_ID>"
  quota_project    = "<YOUR_QUOTA_PROJECT>"
  audit_project_id = "<YOUR_AUDIT_PROJECT_ID>"
  terraform_service_account = "<YOUR_BOOTSTRAP_SA_EMAIL>"
  
  security_team_email = "<YOUR_SECURITY_TEAM_EMAIL>"
  
  enabled_criteria = {
    security        = true
    availability    = true
    confidentiality = true
  }
}