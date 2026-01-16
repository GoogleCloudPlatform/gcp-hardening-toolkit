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

provider "google" {
  project = var.project_id
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# This resource is COMPLIANT with the policy and should be created successfully.
# To test, run: terraform apply -target=google_storage_bucket.compliant_bucket
resource "google_storage_bucket" "compliant_bucket" {
  name          = "compliant-bucket-${random_id.bucket_suffix.hex}"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

# This resource VIOLATES the policy and should fail to create.
# The expected error is "Error 412: Precondition not met".
# This failure proves the custom constraint is working.
# To test, run: terraform apply -target=google_storage_bucket.violating_bucket
resource "google_storage_bucket" "violating_bucket" {
  name          = "violating-bucket-${random_id.bucket_suffix.hex}"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true
  versioning {
    enabled = false
  }
}
