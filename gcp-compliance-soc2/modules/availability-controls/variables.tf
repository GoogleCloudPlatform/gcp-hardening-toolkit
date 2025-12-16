variable "organization_id" {
  description = "GCP Organization ID"
  type        = string
}

variable "parent" {
  description = "Parent resource (organizations/ORG_ID or folders/FOLDER_ID)"
  type        = string
}

variable "enabled" {
  description = "Whether to enable availability controls"
  type        = bool
  default     = true
}

variable "allowed_regions" {
  description = "List of allowed GCP regions"
  type        = list(string)
  default     = ["us-central1", "us-east1"]
}
