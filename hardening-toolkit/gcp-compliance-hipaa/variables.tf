variable "organization_id" {
  description = "The organization ID for which to activate Security Command Center."
  type        = string
}

variable "quota_project" {
  description = "The project to use for quota."
  type        = string
  default     = null
}

variable "log_project_id" {
  description = "The ID of the project where the BigQuery dataset will be created."
  type        = string
  default     = null
}

variable "notification_email" {
  description = "The email address for security alert notifications."
  type        = string
}
