variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "audit_project_id" {
  description = "Project ID where monitoring resources will be created"
  type        = string
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
