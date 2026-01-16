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
resource "google_compute_network" "custom_mode_vpc" {
  name                    = "custom-mode-vpc-test"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "custom_subnet" {
  name                     = "custom-subnet-test"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.custom_mode_vpc.self_link
  project                  = var.project_id
  private_ip_google_access = true
}

# This resource VIOLATES the policy and should fail to create.
resource "google_compute_network" "auto_mode_vpc" {
  name                    = "auto-mode-vpc-test"
  auto_create_subnetworks = true
  project                 = var.project_id
}
