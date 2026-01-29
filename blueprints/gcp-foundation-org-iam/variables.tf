variable "groups" {
  description = "A list of groups to create."
  type = list(object({
    display_name = string
    description  = string
    folder_id    = optional(string)
    roles        = list(string)
  }))
}

variable "customer_id" {
  description = "The customer ID for the organization."
  type        = string
}

variable "domain" {
  description = "The domain of the organization."
  type        = string
}

variable "allow_multi_point_grants" {
  description = "Allow the same group to be defined multiple times for different folder permissions."
  type        = bool
  default     = false
}
