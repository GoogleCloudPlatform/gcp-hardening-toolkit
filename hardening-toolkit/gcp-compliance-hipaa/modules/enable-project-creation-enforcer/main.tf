/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
resource "google_project_service" "cloudfunctions" {
  project = var.enforcer_project_id
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "artifactregistry" {
  project = var.enforcer_project_id
  service = "artifactregistry.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  project = var.enforcer_project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "storage" {
  project = var.enforcer_project_id
  service = "storage.googleapis.com"
}

resource "time_sleep" "wait_for_apis" {
  create_duration = "2m"

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.artifactregistry,
    google_project_service.cloudbuild,
    google_project_service.storage
  ]
}

resource "google_service_account" "function_sa" {
  project      = var.enforcer_project_id
  account_id   = "project-creation-enforcer-sa"
  display_name = "Project Creation Enforcer SA"
}

data "google_project" "project" {
  project_id = var.enforcer_project_id
}

resource "google_storage_bucket_iam_member" "cloudbuild_storage_viewer" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_storage_bucket_iam_member" "legacy_cloudbuild_storage_viewer" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_pubsub_topic" "topic" {
  name    = "project-creation"
  project = var.enforcer_project_id
}

resource "google_logging_organization_sink" "sink" {
  name   = "project-creation-sink"
  org_id = var.organization_id

  destination = "pubsub.googleapis.com/${google_pubsub_topic.topic.id}"
  filter      = "resource.type=\"project\" AND protoPayload.methodName=\"CreateProject\""
}


data "google_iam_policy" "admin" {
  binding {
    role    = "roles/pubsub.publisher"
    members = [google_logging_organization_sink.sink.writer_identity]
  }
}

resource "google_pubsub_topic_iam_policy" "policy" {
  project = google_pubsub_topic.topic.project
  topic   = google_pubsub_topic.topic.name
  policy_data = data.google_iam_policy.admin.policy_data
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.organization_id}-cf-source"
  location = "US"
  project  = var.enforcer_project_id
  uniform_bucket_level_access = true
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "${path.module}/source"
  output_path = "/tmp/source.zip"
}

resource "google_storage_bucket_object" "object" {
  name   = "source.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.source.output_path
}

resource "google_project_service" "run" {
  project = var.enforcer_project_id
  service = "run.googleapis.com"
}

resource "google_project_service" "eventarc" {
  project = var.enforcer_project_id
  service = "eventarc.googleapis.com"
}

resource "google_project_iam_member" "cloudbuild_artifactregistry_writer" {
  project = var.enforcer_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "legacy_cloudbuild_artifactregistry_writer" {
  project = var.enforcer_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "cloudbuild_logs_writer" {
  project = var.enforcer_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_project_iam_member" "compute_build_builder" {
  project = var.enforcer_project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_cloudfunctions2_function" "function" {
  name    = "enable-cloud-asset-api"
  project = var.enforcer_project_id
  location = var.region

  build_config {
    runtime     = "python310"
    entry_point = "enable_cloud_asset_api"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    min_instance_count = 0
    available_memory   = "256Mi"
    timeout_seconds    = 60
    service_account_email = google_service_account.function_sa.email
    ingress_settings = "ALLOW_INTERNAL_AND_GCLB"
  }

  event_trigger {
    trigger_region = var.region
    event_type = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic = google_pubsub_topic.topic.id
    retry_policy = "RETRY_POLICY_RETRY"
  }

  depends_on = [
    time_sleep.wait_for_apis,
    google_project_service.run,
    google_project_service.eventarc,
    google_project_iam_member.cloudbuild_artifactregistry_writer,
    google_project_iam_member.legacy_cloudbuild_artifactregistry_writer,
    google_storage_bucket_iam_member.cloudbuild_storage_viewer,
    google_storage_bucket_iam_member.legacy_cloudbuild_storage_viewer,
    google_project_iam_member.cloudbuild_logs_writer,
    google_project_iam_member.compute_build_builder
  ]
}

resource "google_cloud_run_service_iam_member" "invoker" {
  location = google_cloudfunctions2_function.function.location
  project  = google_cloudfunctions2_function.function.project
  service  = google_cloudfunctions2_function.function.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

resource "google_organization_iam_member" "iam" {
  org_id = var.organization_id
  role   = "roles/serviceusage.serviceUsageAdmin"
  member = "serviceAccount:${google_service_account.function_sa.email}"
}