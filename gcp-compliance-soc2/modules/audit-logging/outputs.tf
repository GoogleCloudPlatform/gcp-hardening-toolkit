output "audit_log_bucket_name" {
  description = "Name of the Cloud Storage bucket containing audit logs with lifecycle policies"
  value       = google_storage_bucket.audit_logs.name
}

output "audit_log_bucket_url" {
  description = "URL to access the audit log bucket"
  value       = "https://console.cloud.google.com/storage/browser/${google_storage_bucket.audit_logs.name}"
}

output "log_sink_writer_identity" {
  description = "Service account identity for log sink"
  value       = google_logging_organization_sink.audit_logs_export.writer_identity
}

output "storage_lifecycle_summary" {
  description = "Summary of storage lifecycle policies"
  value = {
    days_0_to_30    = "STANDARD storage - Fast access"
    days_31_to_90   = "NEARLINE storage - Monthly access"
    days_91_to_180  = "COLDLINE storage - Quarterly access"
    days_181_to_365 = "ARCHIVE storage - Annual access"
    after_365_days  = "Deleted (retention period)"
  }
}
