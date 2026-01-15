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

  organization_id      = "<YOUR_ORGANIZATION_ID>"
  folder_id            = "<YOUR_FOLDER_ID>"  # Optional: scope to specific folder
  quota_project        = "<YOUR_QUOTA_PROJECT>"
  audit_project_id     = "<YOUR_AUDIT_PROJECT_ID>"
  log_bucket_location  = "us-central1"
  
  # Retain audit logs for 2 years
  audit_log_retention_days = 730
  
  # Enable all SOC2 criteria
  enabled_criteria = {
    security        = true
    availability    = true
    confidentiality = true
  }
  
  # Restrict resources to approved regions
  allowed_regions = [
    "us-central1",
    "us-east1",
    "us-west1"
  ]
  
  # Exempt development/testing projects from certain policies
  exempted_projects = [
    "dev-sandbox-123",
    "qa-testing-456"
  ]
  
  # VPC Service Controls configuration
  access_policy_id = "<YOUR_ACCESS_POLICY_ID>"
  allowed_vpc_services = [
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "cloudsql.googleapis.com"
  ]
  
  # Notification channels for different teams
  security_team_email   = "security@example.com"
  compliance_team_email = "compliance@example.com"
  ops_team_email        = "ops@example.com"
}

# Output important information
output "audit_log_bucket" {
  description = "Audit log storage bucket"
  value       = module.soc2_compliance.audit_log_bucket_name
}

output "bigquery_dataset" {
  description = "BigQuery dataset for audit log queries"
  value       = module.soc2_compliance.audit_log_bigquery_dataset
}

output "compliance_summary" {
  description = "SOC2 compliance configuration summary"
  value       = module.soc2_compliance.soc2_compliance_summary
}