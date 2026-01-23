variable "parent" {
  description = "The parent resource to attach the policy to. Must be in the format 'organizations/{organization_id}'."
  type        = string
}


variable "enable_custom_mode_vpc_constraint" {
  description = "Enable the custom mode VPC custom constraint."
  type        = bool
  default     = true
}
