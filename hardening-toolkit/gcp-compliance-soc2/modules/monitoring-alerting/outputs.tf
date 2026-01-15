output "security_notification_channel_id" {
  description = "Notification channel ID for security team"
  value       = google_monitoring_notification_channel.security_team.id
}

output "compliance_notification_channel_id" {
  description = "Notification channel ID for compliance team"
  value       = var.compliance_team_email != null ? google_monitoring_notification_channel.compliance_team[0].id : null
}

output "alert_policy_ids" {
  description = "List of created alert policy IDs"
  value = [
    google_monitoring_alert_policy.privileged_role_grants_alert.id,
    google_monitoring_alert_policy.sa_key_creation_alert.id,
    google_monitoring_alert_policy.gcs_iam_changes_alert.id,
    google_monitoring_alert_policy.org_policy_changes_alert.id
  ]
}
