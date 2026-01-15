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

resource "google_compute_health_check" "default" {
  name               = "test-health-check"
  check_interval_sec = 1
  timeout_sec        = 1

  tcp_health_check {
    port = "80"
  }
}

# This resource is COMPLIANT with the policy and should be created successfully.
# To test, run: terraform apply -target=google_compute_backend_service.compliant_service
resource "google_compute_backend_service" "compliant_service" {
  name          = "logging-enabled-service"
  health_checks = [google_compute_health_check.default.id]

  log_config {
    enable = true
  }
}

# This resource VIOLATES the policy and should fail to create.
# The expected error is "Error 412: Precondition not met".
# This failure proves the custom constraint is working.
# To test, run: terraform apply -target=google_compute_backend_service.violating_service
resource "google_compute_backend_service" "violating_service" {
  name          = "logging-disabled-service"
  health_checks = [google_compute_health_check.default.id]

  # Logging is disabled by default if log_config is not present,
  # or explicitly disabled here to be sure.
  log_config {
    enable = false
  }
}