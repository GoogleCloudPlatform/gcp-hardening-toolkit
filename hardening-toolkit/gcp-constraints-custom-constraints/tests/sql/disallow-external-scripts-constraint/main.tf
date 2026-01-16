terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

variable "project_id" {
  description = "The project ID to host the resources in."
  type        = string
}

provider "google" {
  project = var.project_id
}




# --- Disallow External Scripts Constraint Tests ---

# This resource is COMPLIANT with the policy and should be created successfully.
resource "google_sql_database_instance" "compliant_sql_server" {
  name             = "compliant-sql"
  database_version = "SQLSERVER_2019_STANDARD"
  region           = "us-central1"
  root_password    = "a-good-password"
  settings {
    tier = "db-custom-2-8192"
    database_flags {
      name  = "external scripts enabled"
      value = "off"
    }
  }
}

# This resource VIOLATES the policy and should fail to create.
# The expected error is "Error 412: Precondition not met".
resource "google_sql_database_instance" "violating_sql_server" {
  name             = "violating-sql"
  database_version = "SQLSERVER_2019_STANDARD"
  region           = "us-central1"
  root_password    = "a-good-password"
  settings {
    tier = "db-custom-2-8192"
    database_flags {
      name  = "external scripts enabled"
      value = "on"
    }
  }
}
