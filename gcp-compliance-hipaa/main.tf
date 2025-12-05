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
  user_project_override = true
  billing_project       = var.quota_project
}

module "enable-audit-logs" {
  source          = "./modules/enable-audit-logs"
  organization_id = var.organization_id
  log_project_id  = var.log_project_id
}

module "enable-project-creation-enforcer" {
  source              = "./modules/enable-project-creation-enforcer"
  organization_id     = var.organization_id
  enforcer_project_id = var.quota_project
}

module "enable_security_alerts" {
  source               = "./modules/enable-security-alerts"
  project_id           = var.log_project_id
  notification_email = var.notification_email
}
