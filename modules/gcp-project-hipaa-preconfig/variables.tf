variable "organization_id" {
  description = "The ID of the organization."
  type        = string
}

variable "region" {
  description = "The region where the Cloud Function will be deployed."
  type        = string
  default     = "us-central1"
}

variable "enforcer_project_id" {
  description = "The ID of the project where the enforcer resources will be deployed."
  type        = string
}
