# Copyright 2026 Google LLC
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

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.10.0, < 9.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ==============================================================================
# LOCAL CALCULATIONS & USER IDENTITY NORMALIZATION
# ==============================================================================
# Derives RFC 1035-compliant GCP Compute Engine VM names from user identities:
# - Linux VDIs:   <username>-<domain>-vdi
# - Windows VDIs: <username>-<domain>-win-vdi
# ==============================================================================
locals {
  # 1. Linux VDI User Normalization (<username>-<domain>-vdi)
  linux_vdi_users_map = {
    for raw_identity in var.linux_vdi_users :
    "${trim(substr(trim(replace(lower(trimprefix(raw_identity, "user:")), "/[^a-z0-9]+/", "-"), "-"), 0, 59), "-")}-vdi" => {
      raw_identity = raw_identity
      email        = trimprefix(raw_identity, "user:")
      iam_member   = startswith(raw_identity, "user:") || startswith(raw_identity, "group:") || startswith(raw_identity, "serviceAccount:") ? raw_identity : "user:${trimprefix(raw_identity, "user:")}"
    }
  }

  # 2. Windows VDI User Normalization (<username>-<domain>-win-vdi)
  windows_vdi_users_map = {
    for raw_identity in var.windows_vdi_users :
    "${trim(substr(trim(replace(lower(trimprefix(raw_identity, "user:")), "/[^a-z0-9]+/", "-"), "-"), 0, 55), "-")}-win-vdi" => {
      raw_identity = raw_identity
      email        = trimprefix(raw_identity, "user:")
      iam_member   = startswith(raw_identity, "user:") || startswith(raw_identity, "group:") || startswith(raw_identity, "serviceAccount:") ? raw_identity : "user:${trimprefix(raw_identity, "user:")}"
    }
  }

  # 3. Combined Map of All VDI Instances and Deduplicated Set of User IAM Members
  all_vdi_users_map   = merge(local.linux_vdi_users_map, local.windows_vdi_users_map)
  all_vdi_iam_members = toset([for u in values(local.all_vdi_users_map) : u.iam_member])

  # 4. Break-glass admins that are NOT already VDI users (avoids managing the
  #    same SA-user binding from two resources).
  vdi_admin_only_members = toset([
    for m in var.vdi_admin_members : m
    if !contains(local.all_vdi_iam_members, m)
  ])
}

# ==============================================================================
# 1. API ENABLER
# ==============================================================================
# Enables the required Google Cloud APIs for Compute Engine and IAP Tunneling.
# ==============================================================================
resource "google_project_service" "vdi_apis" {
  for_each = toset([
    "compute.googleapis.com",    # Compute Engine API
    "iap.googleapis.com",        # Identity-Aware Proxy API
    "logging.googleapis.com",    # Cloud Logging API
    "monitoring.googleapis.com", # Cloud Monitoring API
    "osconfig.googleapis.com"    # OS Config API (admin-managed Linux software)
  ])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# ==============================================================================
# 2. FIREWALL RULES & SERVICE ACCOUNT
# ==============================================================================

# 2.1 Allow Inbound IAP Tunneling (Port 22 for SSH, Port 3389 for RDP)
resource "google_compute_firewall" "allow_iap_tunnel" {
  count   = var.create_iap_firewall_rule ? 1 : 0
  name    = "${var.network_name}-allow-iap-tunnel"
  project = var.subnetwork_project != null ? var.subnetwork_project : var.project_id
  network = var.network_name

  # Google Cloud IAP VIP CIDR range (Fixed Google infrastructure VIP)
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  target_tags = ["secure-vdi"]
}

# 2.2 Dedicated Least-Privilege Service Account for VDI VMs
resource "google_service_account" "vdi_sa" {
  count        = length(local.all_vdi_iam_members) > 0 ? 1 : 0
  project      = var.project_id
  account_id   = "vdi-runner-sa"
  display_name = "Secure VDI Runner Service Account"
}

# 2.3 Service Account User permissions for all authorized VDI users
resource "google_service_account_iam_member" "vdi_sa_user" {
  for_each           = local.all_vdi_iam_members
  service_account_id = google_service_account.vdi_sa[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

# ==============================================================================
# 3. COMPUTE ENGINE SECURE LINUX VDI VMS (1:1 DEDICATED PER USER)
# ==============================================================================
# Each user in `var.linux_vdi_users` gets a dedicated Compute Engine Linux VM:
# <username>-<domain>-vdi
# - Shielded VM (Secure Boot + vTPM + Integrity Monitoring)
# - Internal RFC 1918 IP only (No Public Inbound Exposure)
# - OS Login enabled for centralized Cloud Identity authentication
# ==============================================================================
resource "google_compute_instance" "linux_vdi" {
  for_each     = local.linux_vdi_users_map
  name         = each.key
  project      = var.project_id
  machine_type = var.machine_type
  zone         = var.zone

  tags = distinct(concat(["secure-vdi"], var.additional_network_tags))

  # Used by OS Config to target admin-managed software (software.tf):
  # - vdi-os:   all Linux VDIs
  # - vdi-name: a specific user's VDI
  labels = {
    vdi-os   = "linux"
    vdi-name = each.key
  }

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  # Hardened Shielded VM Configuration
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  # Private IP Only (No external IP / access_config block)
  network_interface {
    subnetwork         = var.subnetwork_name
    subnetwork_project = var.subnetwork_project
  }

  service_account {
    email  = google_service_account.vdi_sa[0].email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin          = "TRUE"
    enable-osconfig         = "TRUE"
    enable-guest-attributes = "TRUE"
    vdi-username            = replace(lower(each.value.email), "/[^a-z0-9]+/", "_")
  }

  deletion_protection = false
  depends_on          = [google_project_service.vdi_apis]
}

# Linux Strict 1:1 OS Login Binding (NON-ADMIN: no sudo / root)
# Users can log in (SSH, RDP) but cannot install software or
# change system configuration. Software is installed by administrators through
# Terraform + OS Config (see software.tf / `linux_vdi_software`).
resource "google_compute_instance_iam_member" "linux_vdi_os_login" {
  for_each      = local.linux_vdi_users_map
  project       = var.project_id
  zone          = var.zone
  instance_name = google_compute_instance.linux_vdi[each.key].name
  role          = "roles/compute.osLogin"
  member        = each.value.iam_member
}

# Break-glass administrator access (sudo) on ALL Linux VDIs
resource "google_compute_instance_iam_member" "linux_vdi_admin_login" {
  for_each = {
    for pair in setproduct(keys(local.linux_vdi_users_map), var.vdi_admin_members) :
    "${pair[0]}|${pair[1]}" => { instance = pair[0], member = pair[1] }
  }
  project       = var.project_id
  zone          = var.zone
  instance_name = google_compute_instance.linux_vdi[each.value.instance].name
  role          = "roles/compute.osAdminLogin"
  member        = each.value.member
}

# Linux administrators must be able to act as the VDI runner SA (OS Login)
resource "google_service_account_iam_member" "vdi_admin_sa_user" {
  for_each           = length(local.linux_vdi_users_map) > 0 ? local.vdi_admin_only_members : toset([])
  service_account_id = google_service_account.vdi_sa[0].name
  role               = "roles/iam.serviceAccountUser"
  member             = each.value
}

# ==============================================================================
# 4. COMPUTE ENGINE SECURE WINDOWS VDI VMS (1:1 DEDICATED PER USER)
# ==============================================================================
# Each user in `var.windows_vdi_users` gets a dedicated Compute Engine Windows VM:
# <username>-<domain>-win-vdi
# - Shielded VM (Secure Boot + vTPM + Integrity Monitoring)
# - Internal RFC 1918 IP only (No Public Inbound Exposure)
# - Accessed via IAP TCP Tunneling (Port 3389 RDP)
# ==============================================================================
resource "google_compute_instance" "windows_vdi" {
  for_each     = local.windows_vdi_users_map
  name         = each.key
  project      = var.project_id
  machine_type = var.windows_machine_type
  zone         = var.zone

  tags = distinct(concat(["secure-vdi"], var.additional_network_tags))

  boot_disk {
    initialize_params {
      image = "${var.windows_image_project}/${var.windows_image_family}"
      size  = var.windows_disk_size_gb
      type  = "pd-ssd"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    subnetwork         = var.subnetwork_name
    subnetwork_project = var.subnetwork_project
  }

  service_account {
    email  = google_service_account.vdi_sa[0].email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin          = "TRUE"
    enable-osconfig         = "TRUE"
    enable-guest-attributes = "TRUE"
  }

  deletion_protection = false
  depends_on          = [google_project_service.vdi_apis]
}

# Windows Strict 1:1 Instance Admin (Allows Windows password reset / login)
resource "google_compute_instance_iam_member" "windows_vdi_instance_admin" {
  for_each      = local.windows_vdi_users_map
  project       = var.project_id
  zone          = var.zone
  instance_name = google_compute_instance.windows_vdi[each.key].name
  role          = "roles/compute.instanceAdmin.v1"
  member        = each.value.iam_member
}

# ==============================================================================
# 5. IAP TCP FORWARDING IAM ACCESS (STRICT 1:1 PER-INSTANCE ISOLATION)
# ==============================================================================
# Grants roles/iap.tunnelResourceAccessor strictly on each user's assigned VDI
# instance(s) so users cannot open IAP TCP tunnels to other users' VDIs.
# Break-glass administrators receive project-level tunnel access.
# ==============================================================================
resource "google_iap_tunnel_instance_iam_member" "linux_vdi_iap_tunnel" {
  for_each = var.manage_iap_tunnel_iam ? local.linux_vdi_users_map : {}
  project  = var.project_id
  zone     = var.zone
  instance = google_compute_instance.linux_vdi[each.key].name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value.iam_member
}

resource "google_iap_tunnel_instance_iam_member" "windows_vdi_iap_tunnel" {
  for_each = var.manage_iap_tunnel_iam ? local.windows_vdi_users_map : {}
  project  = var.project_id
  zone     = var.zone
  instance = google_compute_instance.windows_vdi[each.key].name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value.iam_member
}

resource "google_project_iam_member" "vdi_admin_iap_tunnel" {
  for_each = var.manage_iap_tunnel_iam ? toset(var.vdi_admin_members) : toset([])
  project  = var.project_id
  role     = "roles/iap.tunnelResourceAccessor"
  member   = each.value
}
