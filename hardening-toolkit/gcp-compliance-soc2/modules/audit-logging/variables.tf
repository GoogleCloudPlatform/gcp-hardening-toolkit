variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "audit_project_id" {
  description = "Project ID where audit logs will be stored"
  type        = string
}

variable "log_bucket_location" {
  description = "Location for audit log storage bucket"
  type        = string
  default     = "us-central1"
}

variable "audit_log_retention_days" {
  description = "Number of days to retain audit logs"
  type        = number
  default     = 365
}

variable "kms_key_name" {
  description = "The KMS crypto key ID to use for bucket encryption (CMEK)"
  type        = string
}
