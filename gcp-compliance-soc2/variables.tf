variable "organization_id" {
  description = "The GCP organization ID where SOC2 controls will be applied"
  type        = string
}

variable "folder_id" {
  description = "Optional folder ID for scoped deployment (if null, applies to entire organization)"
  type        = string
  default     = null
}

variable "quota_project" {
  description = "The project to use for quota and billing"
  type        = string
}

variable "audit_project_id" {
  description = "The project ID where audit logs and monitoring resources will be created"
  type        = string
}

variable "log_bucket_location" {
  description = "Location for audit log storage bucket"
  type        = string
  default     = "us-central1"
}

variable "audit_log_retention_days" {
  description = "Number of days to retain audit logs (SOC2 requires minimum 365 days)"
  type        = number
  default     = 365
  
  validation {
    condition     = var.audit_log_retention_days >= 365
    error_message = "SOC2 compliance requires minimum 365 days of audit log retention"
  }
}

variable "enabled_criteria" {
  description = "Which SOC2 Trust Services Criteria to enable"
  type = object({
    security        = bool
    availability    = bool
    confidentiality = bool
  })
  default = {
    security        = true
    availability    = true
    confidentiality = true
  }
}

variable "allowed_regions" {
  description = "List of allowed GCP regions for resource deployment (for availability controls)"
  type        = list(string)
  default     = ["us-central1", "us-east1"]
}

variable "exempted_projects" {
  description = "List of project IDs exempt from certain organization policies"
  type        = list(string)
  default     = []
}

variable "access_policy_id" {
  description = "Access Context Manager policy ID for VPC Service Controls (required for confidentiality controls)"
  type        = string
  default     = null
}

variable "allowed_vpc_services" {
  description = "List of allowed services within VPC Service Control perimeter"
  type        = list(string)
  default = [
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "cloudsql.googleapis.com"
  ]
}

variable "security_team_email" {
  description = "Email address for security team notifications"
  type        = string
}

variable "compliance_team_email" {
  description = "Email address for compliance team notifications"
  type        = string
  default     = null
}

variable "ops_team_email" {
  description = "Email address for operations team notifications"
  type        = string
  default     = null
}
