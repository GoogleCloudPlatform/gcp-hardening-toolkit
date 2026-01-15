################################################################################
# Service Account Key Management - Logging Configuration
# NOTE: Log-based metrics and alerts already exist and send to BigPanda
# This configuration only adds centralized log storage for compliance
################################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID for Lumen"
  type        = string
}

variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "log_bucket_location" {
  description = "Location for centralized log bucket"
  type        = string
  default     = "us-central1"
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 365
}

################################################################################
# Centralized Log Bucket for Compliance & Forensics
################################################################################

resource "google_logging_project_bucket_config" "sa_key_audit_logs" {
  project        = var.project_id
  location       = var.log_bucket_location
  retention_days = var.log_retention_days
  bucket_id      = "sa-key-audit-logs"

  description = "Centralized audit logs for service account key management - 365-day retention for compliance"
}

################################################################################
# Log Sink for Service Account Key Events
################################################################################

resource "google_logging_project_sink" "sa_key_events" {
  project     = var.project_id
  name        = "sa-key-events-sink"
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.log_bucket_location}/buckets/sa-key-audit-logs"

  filter = <<-EOT
    resource.type="service_account"
    AND (
      protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
      OR protoPayload.methodName="google.iam.admin.v1.DeleteServiceAccountKey"
    )
  EOT

  unique_writer_identity = true
}

################################################################################
# Outputs
################################################################################

output "log_bucket_name" {
  description = "Name of the centralized log bucket"
  value       = google_logging_project_bucket_config.sa_key_audit_logs.bucket_id
}

output "log_sink_name" {
  description = "Name of the log sink"
  value       = google_logging_project_sink.sa_key_events.name
}

output "log_bucket_url" {
  description = "Console URL to view logs"
  value       = "https://console.cloud.google.com/logs/storage/buckets/${google_logging_project_bucket_config.sa_key_audit_logs.bucket_id}?project=${var.project_id}"
}

################################################################################
# NOTES:
# - Log-based metrics already exist in the environment
# - Alert policies already configured to send to BigPanda
# - This configuration only adds centralized storage for compliance
################################################################################
