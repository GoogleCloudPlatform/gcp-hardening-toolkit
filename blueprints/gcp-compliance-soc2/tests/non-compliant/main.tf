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

# 5. BigQuery - Dataset without default CMEK (Should Fail)
resource "google_bigquery_dataset" "violating_bq_dataset" {

  dataset_id = "violating_dataset_no_cmek"
  location   = "us-central1"
}

# 6. Dataproc - Cluster without CMEK (Should Fail)
resource "google_dataproc_cluster" "violating_dataproc_cluster" {
  name   = "violating-dataproc-cluster"
  region = "us-central1"

  cluster_config {
    gce_cluster_config {
      network    = google_compute_network.test_network_non.id
      subnetwork = google_compute_subnetwork.test_subnetwork_non.id
    }
  }
}

resource "google_compute_subnetwork" "test_subnetwork_non" {
  name          = "non-compliant-dataproc-subnet"
  ip_cidr_range = "10.2.0.0/16"
  region        = "us-central1"
  network       = google_compute_network.test_network_non.id
}

# 7. Compute Disk - Without CSEK (Should Fail)
resource "google_compute_disk" "violating_disk_no_csek" {
  name = "violating-disk-no-csek"
  type = "pd-standard"
  zone = "us-central1-a"
  size = 10
}

# 8. Compute Instance - Using default service account (Should Fail)
resource "google_compute_instance" "violating_instance_default_sa" {
  name         = "violating-instance-default-sa"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.test_network_non.id
  }

  # Using default service account (implicitly)
  # This will use PROJECT_NUMBER-compute@developer.gserviceaccount.com
}

# 9. Compute Instance - Using default SA with full scopes (Should Fail)
resource "google_compute_instance" "violating_instance_default_sa_full_scopes" {
  name         = "violating-instance-default-sa-full-scopes"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.test_network_non.id
  }

  service_account {
    # Using default service account with full cloud-platform scope
    scopes = ["cloud-platform"]
  }
}

# 10. Compute Instance - With IP forwarding enabled (Should Fail)
resource "google_compute_instance" "violating_instance_ip_forwarding" {
  name         = "violating-instance-ip-forwarding"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.test_network_non.id
  }

  can_ip_forward = true
}

# 11. DNS - Managed zone with RSASHA1 algorithm (Should Fail)
resource "google_dns_managed_zone" "violating_zone_rsasha1" {
  name        = "violating-zone-rsasha1"
  dns_name    = "violating-rsasha1.example.com."
  description = "Violating zone with RSASHA1 DNSSEC algorithm"

  dnssec_config {
    state = "on"
    default_key_specs {
      algorithm  = "rsasha1"
      key_type   = "keySigning"
      key_length = 2048
    }
    default_key_specs {
      algorithm  = "rsasha1"
      key_type   = "zoneSigning"
      key_length = 1024
    }
  }
}
