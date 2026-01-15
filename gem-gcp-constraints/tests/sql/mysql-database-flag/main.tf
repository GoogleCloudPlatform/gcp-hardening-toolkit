
# --- MySQL Database Flags Constraint Tests ---

# This resource is COMPLIANT with the policy and should be created successfully.
resource "google_sql_database_instance" "compliant_mysql" {
  name             = "compliant-mysql-test"
  database_version = "MYSQL_8_0"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"
    database_flags {
      name  = "skip_show_database"
      value = "on"
    }
    database_flags {
      name  = "local_infile"
      value = "off"
    }
  }
  deletion_protection = false
}

# This resource VIOLATES the policy and should fail to create.
resource "google_sql_database_instance" "violating_mysql" {
  name             = "violating-mysql-test"
  database_version = "MYSQL_8_0"
  region           = "us-central1"

  settings {
    tier = "db-f1-micro"
    # Missing skip_show_database=on or local_infile=off will violate the policy.
    database_flags {
      name  = "local_infile"
      value = "on"
    }
  }
  deletion_protection = false
}