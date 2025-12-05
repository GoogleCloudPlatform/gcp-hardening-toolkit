################################################################################
# Notification Channel (Used by all alerts)
################################################################################
resource "google_monitoring_notification_channel" "email_channel" {
  project      = var.project_id
  display_name = "Security Administrators Email"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

################################################################################
# Metric filter and alert for Cloud Storage IAM permission changes
################################################################################
resource "google_logging_metric" "gcs_iam_permission_changes" {
  project = var.project_id
  name    = "gcs-iam-permission-changes"
  filter  = "resource.type=\"gcs_bucket\" AND protoPayload.methodName=\"storage.setIamPermissions\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

resource "time_sleep" "wait_for_gcs_iam_permission_changes_metric" {
  create_duration = "240s"
  depends_on      = [google_logging_metric.gcs_iam_permission_changes]
}

resource "google_monitoring_alert_policy" "gcs_iam_permission_changes_alert" {
  project               = var.project_id
  display_name          = "Cloud Storage IAM Permission Changes"
  combiner              = "OR"
  severity              = "WARNING"
  notification_channels = [google_monitoring_notification_channel.email_channel.id]

  conditions {
    display_name = "Cloud Storage IAM Permission Changes"

    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.gcs_iam_permission_changes.name}\" AND resource.type=\"gcs_bucket\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
    }
  }
  
  depends_on = [time_sleep.wait_for_gcs_iam_permission_changes_metric]
}


################################################################################
# Metric filter and alert for DDoS attacks
################################################################################
resource "google_monitoring_alert_policy" "ddos_policy" {
  project               = var.project_id
  display_name          = "DDoS Attack Detected"
  combiner              = "OR"
  severity              = "WARNING"
  notification_channels = [google_monitoring_notification_channel.email_channel.id]

  conditions {
    display_name = "High rate of Pub/Sub publish requests"

    condition_threshold {
      filter     = "resource.type = \"pubsub_topic\" AND metric.type = \"pubsub.googleapis.com/topic/send_request_count\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      threshold_value = var.notification_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields = [
          "metric.label.response_class",
          "metric.label.response_code"
        ]
      }

      trigger {
        count = 1
      }
    }
  }
}
