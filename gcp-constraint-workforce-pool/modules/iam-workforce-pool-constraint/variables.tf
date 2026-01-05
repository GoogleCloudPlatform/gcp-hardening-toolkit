variable "organization_id" {
  description = "The numeric ID of the organization where the policy will be applied."
  type        = string
}

variable "allowed_roles_prefixes" {
  description = "A list of role prefixes that are allowed to be granted to a workforce pool."
  type        = list(string)
  default     = ["roles/iap"]
}

variable "constraint_base_name" {
  description = "The base name for the custom constraint. A random suffix will be added."
  type        = string
  default     = "lockworkforcepools"
}

variable "display_name" {
  description = "The display name for the custom constraint."
  type        = string
  default     = "Lock Role Grants for Workforce Pools"
}

variable "description" {
  description = "The description for the custom constraint."
  type        = string
  default     = "Restricts which non-allowlisted roles can be granted to a workforce pool."
}
