################################################################################
# SOC2 Monitoring & Alerting Module
# Creates notification channels and alert policies for SOC2 compliance monitoring
################################################################################

# Notification channel for security team
resource "google_monitoring_notification_channel" "security_team" {
  project      = var.audit_project_id
  display_name = "SOC2 Security Team"
  type         = "email"
  
  labels = {
    email_address = var.security_team_email
  }
}

# Notification channel for compliance team (optional)
resource "google_monitoring_notification_channel" "compliance_team" {
  count        = var.compliance_team_email != null ? 1 : 0
  project      = var.audit_project_id
  display_name = "SOC2 Compliance Team"
  type         = "email"
  
  labels = {
    email_address = var.compliance_team_email
  }
}

# Notification channel for ops team (optional)
resource "google_monitoring_notification_channel" "ops_team" {
  count        = var.ops_team_email != null ? 1 : 0
  project      = var.audit_project_id
  display_name = "SOC2 Operations Team"
  type         = "email"
  
  labels = {
    email_address = var.ops_team_email
  }
}

################################################################################
# Alert: Privileged IAM Role Grants (CC6.6)
################################################################################
resource "google_logging_metric" "privileged_role_grants" {
  project = var.audit_project_id
  name    = "soc2-privileged-role-grants"
  filter  = <<-EOT
    protoPayload.serviceName="cloudresourcemanager.googleapis.com"
    AND protoPayload.methodName="SetIamPolicy"
    AND (
      protoPayload.request.policy.bindings.role="roles/owner"
      OR protoPayload.request.policy.bindings.role="roles/editor"
    )
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "time_sleep" "wait_for_privileged_role_metric" {
  create_duration = "240s"
  depends_on      = [google_logging_metric.privileged_role_grants]
}

resource "google_monitoring_alert_policy" "privileged_role_grants_alert" {
  project               = var.audit_project_id
  display_name          = "SOC2: Privileged Role Granted"
  combiner              = "OR"
  severity              = "CRITICAL"
  notification_channels = [google_monitoring_notification_channel.security_team.id]

  conditions {
    display_name = "Owner or Editor role granted"

    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.privileged_role_grants.name}\" AND resource.type=\"global\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      threshold_value = 0
    }
  }
  
  depends_on = [time_sleep.wait_for_privileged_role_metric]
}

################################################################################
# Alert: Service Account Key Creation Attempts (CC6.2)
################################################################################
resource "google_logging_metric" "sa_key_creation_attempts" {
  project = var.audit_project_id
  name    = "soc2-sa-key-creation-attempts"
  filter  = <<-EOT
    protoPayload.serviceName="iam.googleapis.com"
    AND protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "time_sleep" "wait_for_sa_key_metric" {
  create_duration = "240s"
  depends_on      = [google_logging_metric.sa_key_creation_attempts]
}

resource "google_monitoring_alert_policy" "sa_key_creation_alert" {
  project               = var.audit_project_id
  display_name          = "SOC2: Service Account Key Creation Attempt"
  combiner              = "OR"
  severity              = "WARNING"
  notification_channels = [google_monitoring_notification_channel.security_team.id]

  conditions {
    display_name = "Service account key creation detected"

    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.sa_key_creation_attempts.name}\" AND resource.type=\"global\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      threshold_value = 0
    }
  }
  
  depends_on = [time_sleep.wait_for_sa_key_metric]
}

################################################################################
# Alert: Cloud Storage IAM Permission Changes (C1.1)
################################################################################
resource "google_logging_metric" "gcs_iam_changes" {
  project = var.audit_project_id
  name    = "soc2-gcs-iam-changes"
  filter  = "resource.type=\"gcs_bucket\" AND protoPayload.methodName=\"storage.setIamPermissions\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "time_sleep" "wait_for_gcs_iam_metric" {
  create_duration = "240s"
  depends_on      = [google_logging_metric.gcs_iam_changes]
}

resource "google_monitoring_alert_policy" "gcs_iam_changes_alert" {
  project               = var.audit_project_id
  display_name          = "SOC2: Cloud Storage IAM Permission Changes"
  combiner              = "OR"
  severity              = "WARNING"
  notification_channels = [google_monitoring_notification_channel.security_team.id]

  conditions {
    display_name = "GCS bucket IAM permissions modified"

    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.gcs_iam_changes.name}\" AND resource.type=\"gcs_bucket\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      threshold_value = 0
    }
  }
  
  depends_on = [time_sleep.wait_for_gcs_iam_metric]
}

################################################################################
# Alert: Organization Policy Changes (CC8.1)
################################################################################
resource "google_logging_metric" "org_policy_changes" {
  project = var.audit_project_id
  name    = "soc2-org-policy-changes"
  filter  = <<-EOT
    protoPayload.serviceName="orgpolicy.googleapis.com"
    AND (
      protoPayload.methodName=~"SetOrgPolicy"
      OR protoPayload.methodName=~"DeleteOrgPolicy"
    )
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "time_sleep" "wait_for_org_policy_metric" {
  create_duration = "240s"
  depends_on      = [google_logging_metric.org_policy_changes]
}

resource "google_monitoring_alert_policy" "org_policy_changes_alert" {
  project               = var.audit_project_id
  display_name          = "SOC2: Organization Policy Changed"
  combiner              = "OR"
  severity              = "CRITICAL"
  notification_channels = [google_monitoring_notification_channel.security_team.id]

  conditions {
    display_name = "Organization policy modified or deleted"

    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.org_policy_changes.name}\" AND resource.type=\"global\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      threshold_value = 0
    }
  }
  
  depends_on = [time_sleep.wait_for_org_policy_metric]
}
