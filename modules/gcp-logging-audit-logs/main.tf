
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

# This resource is needed to enable Data Access audit logs for all services at the project level.
# This is required for the security alerts to function correctly.
resource "google_project_iam_audit_config" "project_audit_config" {
  project = var.log_project_id
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
