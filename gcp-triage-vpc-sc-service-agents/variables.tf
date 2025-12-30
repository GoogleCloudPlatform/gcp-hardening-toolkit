variable "organization_id" {
  description = "The ID of the organization."
  type        = string
}

variable "quota_project_id" {
  description = "The ID of the project to use for API quota and billing."
  type        = string
}

variable "perimeter_name" {
  description = "The name of the service perimeter."
  type        = string
  default     = "vpc_sc_perimeter"
}

variable "policy_name" {
  description = "The name of the access policy."
  type        = string
  default     = "vpc_sc_policy"
}

variable "billing_account_id" {
  description = "The ID of the billing account."
  type        = string
}

variable "folder_id" {
  description = "The ID of the folder to create the projects in."
  type        = string
}

variable "region" {
  description = "The region to create the resources in."
  type        = string
  default     = "us-central1"
}
