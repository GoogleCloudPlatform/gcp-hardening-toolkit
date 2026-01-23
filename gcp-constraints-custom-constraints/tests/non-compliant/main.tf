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

# --- Private Service Access for Cloud SQL (Non-Compliant VPC) ---

resource "google_compute_global_address" "violating_private_ip_address" {
  name          = "violating-private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.violating_pga_test_network.id
}

resource "google_service_networking_connection" "violating_private_vpc_connection" {
  network                 = google_compute_network.violating_pga_test_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.violating_private_ip_address.name]
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

# 2b. DNS Policy - Logging Disabled (Should Fail)
resource "google_dns_policy" "violating_policy" {
  name                      = "violating-dns-policy"
  enable_logging            = false
  enable_inbound_forwarding = false

  networks {
    network_url = google_compute_network.violating_pga_test_network.id
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

# 6. VPC Firewall - Logging Disabled (Should Fail)
resource "google_compute_firewall" "violating_rule" {
  name    = "violating-firewall-no-logging"
  network = google_compute_network.violating_pga_test_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"

  # No log_config block - this should violate the constraint
}

# 7. VPC Firewall - Public Access 0.0.0.0/0 (Should Fail)
resource "google_compute_firewall" "violating_public_access_rule" {
  name    = "violating-firewall-public-access"
  network = google_compute_network.violating_pga_test_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  direction     = "INGRESS"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# 8. Artifact Registry - Public Binding (Violating)
resource "google_artifact_registry_repository" "violating_iam_test_repo" {
  location      = "us-central1"
  repository_id = "violating-iam-test-repo"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "violating_iam_binding" {
  project    = google_artifact_registry_repository.violating_iam_test_repo.project
  location   = google_artifact_registry_repository.violating_iam_test_repo.location
  repository = google_artifact_registry_repository.violating_iam_test_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "allUsers" # Public access, should be DENIED
}

# 9. Cloud SQL - SSL Disabled (Violating)
resource "google_sql_database_instance" "violating_sql_instance" {
  name             = "violating-sql-instance"
  region           = "us-central1"
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      ipv4_enabled    = false
      private_network = google_compute_network.violating_pga_test_network.self_link
    }
  }

  depends_on = [google_service_networking_connection.violating_private_vpc_connection]
}
