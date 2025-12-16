variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "parent" {
  description = "Parent resource (organizations/ORG_ID or folders/FOLDER_ID)"
  type        = string
}

variable "enabled" {
  description = "Whether to enable security controls"
  type        = bool
  default     = true
}

variable "exempted_projects" {
  description = "List of project IDs exempt from certain policies"
  type        = list(string)
  default     = []
}

variable "allowed_domains" {
  description = "List of allowed domains for IAM policy members (null = allow all)"
  type        = list(string)
  default     = null
}
