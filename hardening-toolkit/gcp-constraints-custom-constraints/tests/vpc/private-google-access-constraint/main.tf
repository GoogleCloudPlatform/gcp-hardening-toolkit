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

resource "google_compute_network" "test_network" {
  name                    = "pga-test-network"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# This resource is COMPLIANT with the policy and should be created successfully.
resource "google_compute_subnetwork" "compliant_subnetwork" {
  name                     = "pga-compliant-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.test_network.self_link
  private_ip_google_access = true
  project                  = var.project_id
}

# This resource is NON-COMPLIANT with the policy and should fail to create.
resource "google_compute_subnetwork" "non_compliant_subnetwork" {
  name                     = "pga-non-compliant-subnet"
  ip_cidr_range            = "10.0.2.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.test_network.self_link
  private_ip_google_access = false
  project                  = var.project_id
}
