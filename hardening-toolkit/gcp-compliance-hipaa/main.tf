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