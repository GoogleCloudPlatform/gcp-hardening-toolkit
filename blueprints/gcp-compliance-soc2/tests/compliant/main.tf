terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.45.2"
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

resource "google_compute_network" "test_network" {
  name                    = "compliant-soc2-test-network"
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "compliant-soc2-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.test_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.test_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# 1. Compliant MySQL Instance
resource "google_sql_database_instance" "compliant_mysql" {
  name             = "compliant-mysql-soc2"
  region           = "us-central1"
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
    database_flags {
      name  = "skip_show_database"
      value = "on"
    }
    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ENCRYPTED_ONLY"
      private_network = google_compute_network.test_network.id
    }
  }
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]
}

# 2. Compliant PostgreSQL Instance
resource "google_sql_database_instance" "compliant_postgres" {
  name             = "compliant-postgres-soc2"
  region           = "us-central1"
  database_version = "POSTGRES_15"
  settings {
    tier = "db-f1-micro"
    database_flags {
      name  = "log_connections"
      value = "on"
    }
    database_flags {
      name  = "log_disconnections"
      value = "on"
    }
    database_flags {
      name  = "log_error_verbosity"
      value = "default"
    }
    database_flags {
      name  = "log_min_duration_statement"
      value = "-1"
    }
    database_flags {
      name  = "log_min_error_statement"
      value = "error"
    }
    database_flags {
      name  = "log_min_messages"
      value = "warning"
    }
    database_flags {
      name  = "log_statement"
      value = "ddl"
    }
    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ENCRYPTED_ONLY"
      private_network = google_compute_network.test_network.id
    }
  }
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]
}

# 3. Compliant SQL Server Instance
resource "google_sql_database_instance" "compliant_sqlserver" {
  name             = "compliant-sqlserver-soc2"
  region           = "us-central1"
  database_version = "SQLSERVER_2019_STANDARD"
  root_password    = "CompliantPassword123!" # pragma: allowlist secret
  settings {
    tier = "db-custom-2-3840"
    database_flags {
      name  = "external scripts enabled"
      value = "off"
    }
    database_flags {
      name  = "3625"
      value = "on"
    }
    database_flags {
      name  = "contained database authentication"
      value = "off"
    }
    database_flags {
      name  = "cross db ownership chaining"
      value = "off"
    }
    database_flags {
      name  = "remote access"
      value = "off"
    }
    database_flags {
      name  = "user connections"
      value = "0"
    }
    database_flags {
      name  = "user options"
      value = "0"
    }
    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ENCRYPTED_ONLY"
      private_network = google_compute_network.test_network.id
    }
  }
  deletion_protection = false
  depends_on          = [google_service_networking_connection.private_vpc_connection]
}

# 4. Compliant AlloyDB Instance
resource "google_alloydb_cluster" "compliant_alloydb_cluster" {
  cluster_id = "compliant-alloydb-cluster"
  location   = "us-central1"
  network_config {
  network    = google_compute_network.test_network.id

  }

  initial_user {
    password = "CompliantPassword123!" # pragma: allowlist secret
  }


}

resource "google_alloydb_instance" "compliant_alloydb_instance" {
  cluster       = google_alloydb_cluster.compliant_alloydb_cluster.name
  instance_id   = "compliant-alloydb-instance"
  instance_type = "PRIMARY"

  network_config {
    enable_public_ip = false
  }

  database_flags = {
    log_error_verbosity     = "default"
    log_min_error_statement = "error"
    log_min_messages        = "warning"
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# 5a. DNS - DNSSEC Enabled
resource "google_dns_managed_zone" "compliant_zone" {
  name        = "compliant-zone"
  dns_name    = "compliant.example.com."
  description = "Compliant zone with DNSSEC enabled"
  dnssec_config {
    state = "on"
  }
}

# 5b. DNS Policy - Logging Enabled
resource "google_dns_policy" "compliant_policy" {
  name                      = "compliant-dns-policy"
  enable_logging            = true
  enable_inbound_forwarding = false

  networks {
    network_url = google_compute_network.test_network.id
  }
}
