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

variable "existing_policies" {
  description = "A map of existing organization policies, with constraint names as keys. Used to prevent creating duplicate policies."
  type        = map(any)
  default     = {}
}
