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
################################################################################
# SOC2 Audit Logging Module - Cost-Optimized with Storage Lifecycle
# Enables comprehensive audit logging with tiered storage for cost efficiency
################################################################################

# Enable all audit log types at organization level
resource "google_organization_iam_audit_config" "org_audit_config" {
  org_id  = var.organization_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Enable audit logs at project level for audit project
resource "google_project_iam_audit_config" "project_audit_config" {
  project = var.audit_project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Create centralized audit log bucket with cost-optimized lifecycle policies
resource "google_storage_bucket" "audit_logs" {
  name          = "${var.organization_id}-soc2-audit-logs"
  location      = var.log_bucket_location
  project       = var.audit_project_id
  force_destroy = true

  uniform_bucket_level_access = true

  # CMEK encryption for SOC2 compliance (optional)
  dynamic "encryption" {
    for_each = var.kms_key_name != null ? [1] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }

  versioning {
    enabled = true
  }

  # Lifecycle Rule 1: Transition to Nearline after 30 days
  lifecycle_rule {
    condition {
      age                   = 30
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  # Lifecycle Rule 2: Transition to Coldline after 90 days
  lifecycle_rule {
    condition {
      age                   = 90
      matches_storage_class = ["NEARLINE"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  # Lifecycle Rule 3: Transition to Archive after 180 days
  lifecycle_rule {
    condition {
      age                   = 180
      matches_storage_class = ["COLDLINE"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Lifecycle Rule 4: Delete after retention period
  lifecycle_rule {
    condition {
      age = var.audit_log_retention_days
    }
    action {
      type = "Delete"
    }
  }
}

# Export all audit logs to centralized bucket
resource "google_logging_organization_sink" "audit_logs_export" {
  name   = "soc2-audit-logs-export"
  org_id = var.organization_id

  destination = "storage.googleapis.com/${google_storage_bucket.audit_logs.name}"

  filter = <<-EOT
    logName=~"logs/cloudaudit.googleapis.com"
  EOT

  include_children = true
}

# Grant sink permission to write to bucket
resource "google_storage_bucket_iam_member" "audit_log_sink_writer" {
  bucket = google_storage_bucket.audit_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_organization_sink.audit_logs_export.writer_identity
}