terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {
  project = var.project_id
}

variable "project_id" {
  description = "The project ID to host the test resources."
  type        = string
}

# This resource is COMPLIANT with the policy and should be created successfully.
resource "google_dns_managed_zone" "compliant_zone" {
  name        = "compliant-zone"
  dns_name    = "compliant.example.com."
  description = "Compliant zone with DNSSEC enabled"
  dnssec_config {
    state = "on"
  }
}

# This resource VIOLATES the policy and should fail to create.
resource "google_dns_managed_zone" "violating_zone" {
  name        = "violating-zone"
  dns_name    = "violating.example.com."
  description = "Violating zone with DNSSEC disabled"
  dnssec_config {
    state = "off"
  }
}