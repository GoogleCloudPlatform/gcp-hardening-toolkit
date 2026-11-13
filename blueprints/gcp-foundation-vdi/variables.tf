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

# ==============================================================================
# VARIABLE DEFINITIONS: Enterprise Compute Engine VDI
# ==============================================================================

variable "project_id" {
  description = "The Google Cloud Project ID where the VDI resources will be deployed."
  type        = string
}

variable "region" {
  description = "Google Cloud region for the VDI infrastructure (e.g. 'us-central1', 'europe-west1')."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud zone for Compute Engine VDI instances."
  type        = string
  default     = "us-central1-a"
}

# ------------------------------------------------------------------------------
# Networking Configuration (Using Pre-Existing Provided Network)
# ------------------------------------------------------------------------------

variable "subnetwork_project" {
  description = "The project ID of the Shared VPC Host Project hosting the subnetwork. Required when deploying into a Shared VPC."
  type        = string
  default     = null
}

variable "network_name" {
  description = "Name of the existing VPC network to use for VDI."
  type        = string
  default     = "vdi-isolated-vpc"
}

variable "subnetwork_name" {
  description = "Name of the existing subnetwork to use for VDI."
  type        = string
  default     = "vdi-workstations-subnet"
}

variable "additional_network_tags" {
  description = "Additional Compute Engine network tags to attach to all VDI instances alongside 'secure-vdi'."
  type        = list(string)
  default     = []
}

variable "create_iap_firewall_rule" {
  description = "If true, provisions a firewall rule allowing inbound Cloud IAP traffic (TCP ports 22 and 3389) on the provided VPC network."
  type        = bool
  default     = true
}

variable "manage_iap_tunnel_iam" {
  description = "If true, provisions per-instance roles/iap.tunnelResourceAccessor IAM bindings for VDI users (and project-level bindings for vdi_admin_members). Set to false if IAP permissions are managed externally."
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Linux VDI Configuration (<username>-<domain>-vdi)
# ------------------------------------------------------------------------------

variable "linux_vdi_users" {
  description = "List of user email addresses (e.g. 'alice@example.com', 'bob@example.com') to automatically provision dedicated 1:1 Linux VDIs for. Users get roles/compute.osLogin (NO sudo)."
  type        = list(string)
  default     = []
}

variable "vdi_admin_members" {
  description = "IAM members with break-glass sudo on ALL Linux VDIs (roles/compute.osAdminLogin), e.g. 'group:vdi-admins@example.com' or 'user:admin@example.com' (IAM prefix required). Routine software installs should go through `linux_vdi_software` instead. Does not affect Windows VDIs (whose users are already local admins)."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for m in var.vdi_admin_members : can(regex("^(user|group|serviceAccount):", m))])
    error_message = "vdi_admin_members entries must start with 'user:', 'group:' or 'serviceAccount:'."
  }
}

variable "machine_type" {
  description = "Compute Engine machine type for the Linux VDI instances."
  type        = string
  default     = "e2-standard-4"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB for each Linux VDI VM."
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "Disk type for the Linux VDI VM boot disks (e.g. 'pd-balanced', 'pd-ssd', 'pd-standard')."
  type        = string
  default     = "pd-balanced"
}

variable "os_image" {
  description = "Compute Engine image family or image name for Linux VDI instances (e.g. 'debian-cloud/debian-12', 'ubuntu-os-cloud/ubuntu-2204-lts')."
  type        = string
  default     = "debian-cloud/debian-12"
}

# ------------------------------------------------------------------------------
# Windows VDI Configuration (<username>-<domain>-win-vdi)
# ------------------------------------------------------------------------------

variable "windows_vdi_users" {
  description = "List of user email addresses (e.g. 'jane@example.com') to automatically provision dedicated 1:1 Windows Desktop VDIs for."
  type        = list(string)
  default     = []
}

variable "windows_machine_type" {
  description = "Machine type for the Windows VDI instances (recommending >= 4 vCPUs / 16 GB for Windows Desktop GUI)."
  type        = string
  default     = "n2-standard-4"
}

variable "windows_image_family" {
  description = "Compute Engine OS image family for Windows VDI."
  type        = string
  default     = "windows-2022"
}

variable "windows_image_project" {
  description = "Project hosting the Windows image."
  type        = string
  default     = "windows-cloud"
}

variable "windows_disk_size_gb" {
  description = "Boot disk size in GB for the Windows VDI VMs."
  type        = number
  default     = 100
}
