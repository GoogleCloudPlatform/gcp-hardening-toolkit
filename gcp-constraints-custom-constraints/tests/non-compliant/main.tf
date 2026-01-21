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

resource "random_id" "violating_bucket_suffix" {
  byte_length = 4
}

resource "google_compute_health_check" "violating_hc" {
  name               = "violating-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_network" "violating_pga_test_network" {
  name                    = "violating-pga-test-network"
  auto_create_subnetworks = false
}

# --- Non-Compliant (Violating) Resources ---

# 1. Compute - Backend Service Logging Disabled (Should Fail)
resource "google_compute_backend_service" "violating_service" {
  name          = "violating-logging-service"
  health_checks = [google_compute_health_check.violating_hc.id]

  log_config {
    enable = false
  }
}

# 2. DNS - DNSSEC Disabled (Should Fail)
resource "google_dns_managed_zone" "violating_zone" {
  name        = "violating-zone"
  dns_name    = "violating.example.com."
  description = "Violating zone with DNSSEC disabled"
  dnssec_config {
    state = "off"
  }
}

# 3. Storage - Bucket Versioning Disabled (Should Fail)
resource "google_storage_bucket" "violating_bucket" {
  name                        = "violating-bucket-${random_id.violating_bucket_suffix.hex}"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true

  versioning {
    enabled = false
  }
}

# 4. VPC - Auto Mode VPC (Should Fail)
resource "google_compute_network" "auto_mode_vpc" {
  name                    = "violating-auto-mode-vpc"
  auto_create_subnetworks = true
}

# 5. VPC - Private Google Access Disabled (Should Fail)
resource "google_compute_subnetwork" "non_compliant_subnetwork" {
  name                     = "violating-pga-subnet"
  ip_cidr_range            = "10.0.2.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.violating_pga_test_network.self_link
  private_ip_google_access = false
}
