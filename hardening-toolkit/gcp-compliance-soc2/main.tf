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
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.45.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11.1"
    }
  }
}

provider "google" {
  # Optional: Use service account impersonation if provided, otherwise use user credentials
  impersonate_service_account = var.terraform_service_account
  user_project_override       = true
  billing_project             = var.quota_project
}

# Module 1: Security Controls (Common Criteria CC1-CC9)
module "security-controls" {
  source = "./modules/security-controls"
  
  parent             = var.folder_id != null ? "folders/${var.folder_id}" : "organizations/${var.organization_id}"
  existing_policies  = var.existing_policies
  exempted_projects  = var.exempted_projects
  enabled            = var.enabled_criteria.security
  allowed_domains    = var.allowed_domains
}

# Module 2: Availability Controls (A1.1-A1.3)
module "availability-controls" {
  source = "./modules/availability-controls"
  
  parent            = var.folder_id != null ? "folders/${var.folder_id}" : "organizations/${var.organization_id}"
  allowed_regions   = var.allowed_regions
  enabled           = var.enabled_criteria.availability
  existing_policies = var.existing_policies
}

# Module 3: Confidentiality Controls (C1.1-C1.2)
module "confidentiality-controls" {
  source = "./modules/confidentiality-controls"

  parent              = var.folder_id != null ? "folders/${var.folder_id}" : "organizations/${var.organization_id}"
  existing_policies   = var.existing_policies
  enabled             = var.enabled_criteria.confidentiality
}

# Module 4: Audit Logging (Required for all SOC2 criteria)
module "audit-logging" {
  source = "./modules/audit-logging"
  
  organization_id          = var.organization_id
  audit_project_id         = var.audit_project_id
  log_bucket_location      = var.log_bucket_location
  audit_log_retention_days = var.audit_log_retention_days
  kms_key_name             = var.kms_key_name
}

# Module 5: Monitoring & Alerting
module "monitoring-alerting" {
  source = "./modules/monitoring-alerting"
  
  organization_id       = var.organization_id
  audit_project_id      = var.audit_project_id
  security_team_email   = var.security_team_email
  compliance_team_email = var.compliance_team_email
  ops_team_email        = var.ops_team_email
}
