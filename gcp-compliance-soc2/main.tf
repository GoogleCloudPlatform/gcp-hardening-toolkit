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
  impersonate_service_account = "terraform-sa@seed-prj-470417.iam.gserviceaccount.com"
  user_project_override       = true
  billing_project             = var.quota_project
}

# Module 1: Security Controls (Common Criteria CC1-CC9)
module "security-controls" {
  source = "./modules/security-controls"
  
  organization_id    = var.organization_id
  parent             = var.folder_id != null ? "folders/${var.folder_id}" : "organizations/${var.organization_id}"
  exempted_projects  = var.exempted_projects
  enabled            = var.enabled_criteria.security
}

# Module 2: Availability Controls (A1.1-A1.3)
module "availability-controls" {
  source = "./modules/availability-controls"
  
  organization_id   = var.organization_id
  parent            = var.folder_id != null ? "folders/${var.folder_id}" : "organizations/${var.organization_id}"
  allowed_regions   = var.allowed_regions
  enabled           = var.enabled_criteria.availability
}

# Module 3: Confidentiality Controls (C1.1-C1.2)
module "confidentiality-controls" {
  source = "./modules/confidentiality-controls"
  
  organization_id     = var.organization_id
  parent              = var.folder_id != null ? "folders/${var.folder_id}" : "organizations/${var.organization_id}"
  access_policy_id    = var.access_policy_id
  allowed_vpc_services = var.allowed_vpc_services
  enabled             = var.enabled_criteria.confidentiality
}

# Module 4: Audit Logging (Required for all SOC2 criteria)
module "audit-logging" {
  source = "./modules/audit-logging"
  
  organization_id          = var.organization_id
  audit_project_id         = var.audit_project_id
  log_bucket_location      = var.log_bucket_location
  audit_log_retention_days = var.audit_log_retention_days
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
