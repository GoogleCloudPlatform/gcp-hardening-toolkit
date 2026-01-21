
variable "parent" {
  description = "The parent resource to attach the policy to. Must be in the format 'organizations/{organization_id}' or 'folders/{folder_id}'."
  type        = string
}
# --- Toggle Variables ---

variable "enable_sql_flags" {
  type    = bool
  default = false
}

variable "enable_sql_external_scripts" {
  type    = bool
  default = false
}

variable "enable_vpc_custom_mode" {
  type    = bool
  default = false
}

variable "enable_vpc_google_access" {
  type    = bool
  default = false
}

variable "enable_dns_dnssec" {
  type    = bool
  default = false
}

variable "enable_gcs_versioning" {
  type    = bool
  default = false
}

variable "enable_backend_logging" {
  type    = bool
  default = false
}
