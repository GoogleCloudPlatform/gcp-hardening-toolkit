terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

variable "project_id" {
  description = "The project ID to host the test resources."
  type        = string
}

provider "google" {
  project = var.project_id
}

# --- Shared Resources ---

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "google_compute_health_check" "default" {
  name               = "compliant-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = "80"
  }
}

# resource "google_compute_network" "test_pga_network" {
#   name                    = "compliant-pga-test-network"
#   auto_create_subnetworks = false
# }

# --- Compliant Resources ---

# 1. Compute - Backend Service Logging Enabled
resource "google_compute_backend_service" "compliant_service" {
  name          = "compliant-logging-service"
  health_checks = [google_compute_health_check.default.id]

  log_config {
    enable = true
  }
}

# 2. DNS - DNSSEC Enabled
resource "google_dns_managed_zone" "compliant_zone" {
  name        = "compliant-zone"
  dns_name    = "compliant.example.com."
  description = "Compliant zone with DNSSEC enabled"
  dnssec_config {
    state = "on"
  }
}

# 3. Storage - Bucket Versioning Enabled
resource "google_storage_bucket" "compliant_bucket" {
  name                        = "compliant-bucket-${random_id.bucket_suffix.hex}"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

# 4. VPC - Custom Mode VPC
resource "google_compute_network" "custom_mode_vpc" {
  name                    = "compliant-custom-mode-vpc"
  auto_create_subnetworks = false
}

# 5. VPC - Private Google Access Enabled
resource "google_compute_subnetwork" "compliant_subnetwork" {
  name                     = "compliant-pga-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.custom_mode_vpc.self_link
  private_ip_google_access = true
}
