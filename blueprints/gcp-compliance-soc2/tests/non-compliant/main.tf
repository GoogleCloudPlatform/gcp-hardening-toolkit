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

resource "google_compute_network" "test_network_non" {
  name                    = "non-compliant-soc2-test-network"
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "private_ip_address_non" {
  name          = "non-compliant-soc2-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.test_network_non.id
}

resource "google_service_networking_connection" "private_vpc_connection_non" {
  network                 = google_compute_network.test_network_non.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address_non.name]
}

resource "google_alloydb_cluster" "violating_alloydb_cluster" {
  cluster_id = "violating-alloydb-cluster"
  location   = "us-central1"
  network_config {
    network    = google_compute_network.test_network_non.id
  }

  initial_user {
    password = "ViolatingPassword123!" # pragma: allowlist secret
  }
}

resource "google_alloydb_instance" "violating_alloydb_instance" {
  cluster       = google_alloydb_cluster.violating_alloydb_cluster.name
  instance_id   = "violating-alloydb-instance"
  instance_type = "PRIMARY"

  network_config {
    enable_public_ip = true
  }

  database_flags = {
    log_error_verbosity     = "terse"
    log_min_error_statement = "fatal"
    log_min_messages        = "info"
  }

  depends_on = [google_service_networking_connection.private_vpc_connection_non]
}

resource "google_alloydb_cluster" "violating_alloydb_log_verbosity_cluster" {
  cluster_id = "violating-alloydb-log-cluster"
  location   = "us-central1"
  network_config {
    network = google_compute_network.test_network_non.id
  }

  initial_user {
    password = "ViolatingPassword123!" # pragma: allowlist secret
  }
}

resource "google_alloydb_instance" "violating_alloydb_log_verbosity_instance" {
  cluster       = google_alloydb_cluster.violating_alloydb_log_verbosity_cluster.name
  instance_id   = "violating-alloydb-log-instance"
  instance_type = "PRIMARY"

  network_config {
    enable_public_ip = false
  }

  depends_on = [google_service_networking_connection.private_vpc_connection_non]
}

# 1. Violating MySQL Instance (skip_show_database is off or missing)
resource "google_sql_database_instance" "violating_mysql_skip_show" {
  name             = "violating-mysql-skip-show"
  region           = "us-central1"
  database_version = "MYSQL_8_0"
  settings {
    tier = "db-f1-micro"
    database_flags {
      name  = "skip_show_database"
      value = "off"
    }

    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      private_network = google_compute_network.test_network_non.id
    }
  }
  deletion_protection = false
}

# 2. Violating PostgreSQL Instances
resource "google_sql_database_instance" "violating_postgres_log_connections" {
  name             = "violating-postgres-log-conn"
  region           = "us-central1"
  database_version = "POSTGRES_15"
  settings {
    tier = "db-f1-micro"
    database_flags {
      name  = "log_connections"
      value = "off"
    }
    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      private_network = google_compute_network.test_network_non.id
    }
  }
  deletion_protection = false
}

resource "google_sql_database_instance" "violating_postgres_log_stmt" {
  name             = "violating-postgres-log-stmt"
  region           = "us-central1"
  database_version = "POSTGRES_15"
  settings {
    tier = "db-f1-micro"
    database_flags {
      name  = "log_statement"
      value = "all" # Should be 'ddl'
    }
    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      private_network = google_compute_network.test_network_non.id
    }
  }
  deletion_protection = false
}

# 3. Violating SQL Server Instances
resource "google_sql_database_instance" "violating_sqlserver_remote_access" {
  name             = "violating-sql-remote"
  region           = "us-central1"
  database_version = "SQLSERVER_2019_STANDARD"
  root_password    = "ViolatingPassword123!" # pragma: allowlist secret
  settings {
    tier = "db-custom-2-3840"
    database_flags {
      name  = "remote access"
      value = "on"
    }
    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      private_network = google_compute_network.test_network_non.id
    }
  }
  deletion_protection = false
}

resource "google_sql_database_instance" "violating_sqlserver_ext_scripts" {
  name             = "violating-sql-scripts"
  region           = "us-central1"
  database_version = "SQLSERVER_2019_STANDARD"
  root_password    = "ViolatingPassword123!" # pragma: allowlist secret
  settings {
    tier = "db-custom-2-3840"
    database_flags {
      name  = "external scripts enabled"
      value = "on"
    }
    ip_configuration {
      ipv4_enabled    = false
      ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
      private_network = google_compute_network.test_network_non.id
    }
  }
  deletion_protection = false
}

resource "google_sql_database_instance" "violating_sqlserver_contained_auth" {
  name             = "violating-sql-auth"
  region           = "us-central1"
  database_version = "SQLSERVER_2019_STANDARD"
  root_password    = "ViolatingPassword123!" # pragma: allowlist secret
  settings {
    tier = "db-custom-2-3840"
    database_flags {
      name  = "contained database authentication"
      value = "on"
    }
    ip_configuration {
        ssl_mode        = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    }
  }
  deletion_protection = false
}

# 4a. DNS - DNSSEC Disabled (Should Fail)
resource "google_dns_managed_zone" "violating_zone" {
  name        = "violating-zone"
  dns_name    = "violating.example.com."
  description = "Violating zone with DNSSEC disabled"
  dnssec_config {
    state = "off"
  }
}

# 4b. DNS Policy - Logging Disabled (Should Fail)
resource "google_dns_policy" "violating_policy" {
  name                      = "violating-dns-policy"
  enable_logging            = false
  enable_inbound_forwarding = false

  networks {
    network_url = google_compute_network.test_network_non.id
  }
}
