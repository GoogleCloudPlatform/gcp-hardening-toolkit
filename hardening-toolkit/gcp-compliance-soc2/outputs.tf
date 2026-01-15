output "audit_log_bucket_name" {
  description = "Name of the Cloud Storage bucket containing audit logs with lifecycle policies"
  value       = module.audit-logging.audit_log_bucket_name
}

output "audit_log_bucket_url" {
  description = "URL to access the audit log bucket"
  value       = module.audit-logging.audit_log_bucket_url
}

output "storage_lifecycle_summary" {
  description = "Storage lifecycle tier summary"
  value       = module.audit-logging.storage_lifecycle_summary
}

output "security_notification_channel_id" {
  description = "Monitoring notification channel ID for security team"
  value       = module.monitoring-alerting.security_notification_channel_id
}

output "enabled_organization_policies" {
  description = "List of organization policies enabled for SOC2 compliance"
  value = concat(
    var.enabled_criteria.security ? module.security-controls.enabled_policies : [],
    var.enabled_criteria.availability ? module.availability-controls.enabled_policies : [],
    var.enabled_criteria.confidentiality ? module.confidentiality-controls.enabled_policies : []
  )
}

output "soc2_compliance_summary" {
  description = "Summary of enabled SOC2 controls"
  value = {
    security_controls        = var.enabled_criteria.security
    availability_controls    = var.enabled_criteria.availability
    confidentiality_controls = var.enabled_criteria.confidentiality
    audit_log_retention_days = var.audit_log_retention_days
    deployment_scope         = var.folder_id != null ? "folder:${var.folder_id}" : "organization:${var.organization_id}"
  }
}
