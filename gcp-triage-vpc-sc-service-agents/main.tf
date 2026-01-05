# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provider "google" {
  user_project_override = true
  billing_project       = var.quota_project_id
}

terraform {
  required_providers {
    time = {
      source  = "hashicorp/time"
      version = "0.11.1"
    }
  }
}

# -------------------------------------------------------
# Random IDs
#
# Fixes Error 409 - Project ID Conflict.
# -------------------------------------------------------
resource "random_id" "p1_suffix" {
  byte_length = 4
}

resource "random_id" "p2_suffix" {
  byte_length = 4
}

resource "random_id" "attacker_project_suffix" {
  byte_length = 4
}

# -------------------------------------------------------
# Projects
# -------------------------------------------------------
resource "google_project" "project_1" {
  name = "vpc-sc-project-1"
  # Use random suffix to avoid conflicts.
  project_id      = "vpc-sc-project-1-${random_id.p1_suffix.hex}"
  folder_id       = var.folder_id
  billing_account = var.billing_account_id
}

resource "google_project" "project_2" {
  name = "vpc-sc-project-2"
  # Use random suffix to avoid conflicts.
  project_id      = "vpc-sc-project-2-${random_id.p2_suffix.hex}"
  folder_id       = var.folder_id
  billing_account = var.billing_account_id
}

resource "google_project" "attacker_project" {
  name            = "vpc-sc-attacker"
  project_id      = "vpc-sc-attacker-${random_id.attacker_project_suffix.hex}"
  folder_id       = var.folder_id
  billing_account = var.billing_account_id
}

resource "google_compute_network" "vpc_network" {
  name                    = "test-network"
  project                 = google_project.project_1.project_id
  auto_create_subnetworks = "true"
}

# =======================================================================
# 1. APIs & Networking (Base Infrastructure)
# =======================================================================
resource "google_project_service" "enabled_apis" {
  project = google_project.project_1.project_id
  for_each = toset([
    "compute.googleapis.com",
    "storage-component.googleapis.com",
    "sqladmin.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com",
    "aiplatform.googleapis.com",
    "notebooks.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# =======================================================================
# 2. Static Resources
#
# Preserved from your original script.
# =======================================================================
resource "google_compute_instance" "vm_static" {
  count        = 2
  project      = google_project.project_1.project_id
  name         = "vm-${count.index + 1}"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  shielded_instance_config {
    enable_secure_boot = true
  }
  network_interface {
    network = google_compute_network.vpc_network.self_link
  }
}

resource "google_storage_bucket" "buckets_static" {
  count                       = 2
  project                     = google_project.project_1.project_id
  name                        = "${google_project.project_1.project_id}-bucket-${count.index + 1}"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.enabled_apis]
}

resource "google_sql_database_instance" "sql_instance" {
  project          = google_project.project_1.project_id
  name             = "sql-instance"
  database_version = "POSTGRES_13"
  region           = "us-central1"
  settings {
    tier = "db-f1-micro"
  }
  # Added for easier testing teardown.
  deletion_protection = false
  depends_on          = [google_project_service.enabled_apis, google_compute_network.vpc_network]
}

# =======================================================================
# 3. Active Trigger: Storage Service Agent (Every 10m)
# =======================================================================
# The Attack Target: A Topic in the external project.
resource "google_pubsub_topic" "attacker_topic" {
  project = google_project.attacker_project.project_id
  name    = "attacker-topic-sink"
}

# Grant Victim's GCS Agent permission to publish so IAM passes, and VPC-SC fails it.
data "google_storage_project_service_account" "gcs_account" {
  project = google_project.project_1.project_id
}
resource "google_pubsub_topic_iam_member" "gcs_sa_publisher" {
  project = google_project.attacker_project.project_id
  topic   = google_pubsub_topic.attacker_topic.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}

# The Trigger Bucket: Notifications pointed at the external topic.
resource "google_storage_bucket" "trigger_bucket" {
  project                     = google_project.project_1.project_id
  name                        = "${google_project.project_1.project_id}-trigger-bucket"
  location                    = "US"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.trigger_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.attacker_topic.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_member.gcs_sa_publisher]
}

# The Automation: Scheduler writes a file every 10 mins to trigger the notification.
resource "google_service_account" "trigger_sa" {
  project      = google_project.project_1.project_id
  account_id   = "scheduler-trigger-sa"
  display_name = "Scheduler Trigger SA"
}
resource "google_storage_bucket_iam_member" "trigger_sa_write" {
  bucket = google_storage_bucket.trigger_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.trigger_sa.email}"
}
resource "google_cloud_scheduler_job" "file_writer" {
  project     = google_project.project_1.project_id
  name        = "trigger-gcs-violation-job"
  description = "Writes a file every 10m to trigger cross-project GCS notification"
  schedule    = "*/10 * * * *"
  region      = "us-central1"
  http_target {
    uri         = "https://storage.googleapis.com/storage/v1/b/${google_storage_bucket.trigger_bucket.name}/o?name=violation-trigger"
    http_method = "POST"
    oauth_token {
      service_account_email = google_service_account.trigger_sa.email
    }
  }
  depends_on = [google_project_service.enabled_apis]
}
