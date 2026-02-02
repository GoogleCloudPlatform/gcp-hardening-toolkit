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

# 2a. DNS - DNSSEC Enabled
resource "google_dns_managed_zone" "compliant_zone" {
  name        = "compliant-zone"
  dns_name    = "compliant.example.com."
  description = "Compliant zone with DNSSEC enabled"
  dnssec_config {
    state = "on"
  }
}

# 2b. DNS Policy - Logging Enabled
resource "google_dns_policy" "compliant_policy" {
  name                      = "compliant-dns-policy"
  enable_logging            = true
  enable_inbound_forwarding = false

  networks {
    network_url = google_compute_network.custom_mode_vpc.id
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

# --- Private Service Access for Cloud SQL ---

resource "google_compute_global_address" "private_ip_address" {
  name          = "compliant-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.custom_mode_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.custom_mode_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# 5. VPC - Private Google Access Enabled
resource "google_compute_subnetwork" "compliant_subnetwork" {
  name                     = "compliant-pga-subnet"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.custom_mode_vpc.self_link
  private_ip_google_access = true
}

# 6. VPC Firewall - Logging Enabled
resource "google_compute_firewall" "compliant_rule" {
  name    = "compliant-firewall-with-logging"
  network = google_compute_network.custom_mode_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["10.1.0.0/24"]
  direction     = "INGRESS"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# 7. VPC Firewall - Specific IP Ranges (No Public Access)
resource "google_compute_firewall" "compliant_specific_range_rule" {
  name    = "compliant-firewall-specific-ranges"
  network = google_compute_network.custom_mode_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
  direction     = "INGRESS"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}


# 8. Artifact Registry - Internal Binding (Compliant)
resource "google_service_account" "compliant_test_sa" {
  account_id   = "compliant-test-sa"
  display_name = "Test Service Account for IAM Constraint"
}

resource "google_artifact_registry_repository" "compliant_iam_test_repo" {
  location      = "us-central1"
  repository_id = "compliant-iam-test-repo"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "compliant_iam_binding" {
  project    = google_artifact_registry_repository.compliant_iam_test_repo.project
  location   = google_artifact_registry_repository.compliant_iam_test_repo.location
  repository = google_artifact_registry_repository.compliant_iam_test_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.compliant_test_sa.email}"
}

# 9. Cloud SQL - SSL Enforcement (Compliant)
resource "google_sql_database_instance" "compliant_sql_instance" {
  name             = "compliant-sql-instance"
  region           = "us-central1"
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ssl_mode        = "ENCRYPTED_ONLY"
      ipv4_enabled    = false
      private_network = google_compute_network.custom_mode_vpc.self_link
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}
