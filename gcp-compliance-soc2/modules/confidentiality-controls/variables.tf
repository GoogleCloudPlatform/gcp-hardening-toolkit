variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "parent" {
  description = "Parent resource (organizations/ORG_ID or folders/FOLDER_ID)"
  type        = string
}

variable "enabled" {
  description = "Whether to enable confidentiality controls"
  type        = bool
  default     = true
}

variable "access_policy_id" {
  description = "Access Context Manager policy ID for VPC Service Controls"
  type        = string
  default     = null
}

variable "allowed_vpc_services" {
  description = "List of allowed services within VPC Service Control perimeter"
  type        = list(string)
  default     = []
}
