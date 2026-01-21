
variable "project_id" {
  description = "The Google Cloud project ID to use for API calls."
  type        = string
}

variable "billing_project" {
  description = "The Google Cloud billing project ID to use for API calls."
  type        = string
}

variable "parent" {
  type        = string
  description = "The parent resource to attach the policy to. Must be in the format 'organizations/{organization_id}', 'folders/{folder_id}', or 'projects/{project_id}'."
}

variable "enable_dns_constraint" {
  type        = bool
  description = "Enable the DNSSEC custom constraint."
  default     = true
}

variable "enable_storage_constraint" {
  type        = bool
  description = "Enable the Cloud Storage bucket versioning custom constraint."
  default     = true
}

variable "enable_vpc_private_google_access_constraint" {
  type        = bool
  description = "Enable the VPC private Google access custom constraint."
  default     = true
}

variable "enable_vpc_custom_mode_constraint" {
  type        = bool
  description = "Enable the custom mode VPC custom constraint."
  default     = true
}

variable "enable_compute_backend_service_logging_constraint" {
  type        = bool
  description = "Enable the Backend Service Logging custom constraint."
  default     = true
}
