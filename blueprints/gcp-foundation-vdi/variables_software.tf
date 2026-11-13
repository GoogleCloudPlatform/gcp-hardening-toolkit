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
# VARIABLE DEFINITIONS: Admin-Managed VDI Software (OS Config)
# ==============================================================================

variable "linux_vdi_software" {
  description = <<-EOT
    Map of software bundles installed (and kept installed) on Linux VDIs by OS Config.
    VDI users have no sudo, so this is the supported way to install software.
    Each bundle becomes its own OS policy assignment (a failure in one bundle does not block others).

    Keys: lowercase, start with a letter, [a-z0-9-], max 40 chars (e.g. "dev-tools").
    - description:    optional free text.
    - packages:       APT package names (from the Debian repos or `apt_repository`).
    - apt_repository: optional third-party APT repo added BEFORE the packages are installed.
    - deb_packages:   optional .deb files downloaded from a URL, pinned by SHA256 checksum.
    - users:          optional list of VDI user emails (from `linux_vdi_users`) to target.
                      Empty = ALL Linux VDIs.

    NOTE: removing a package from a bundle does NOT uninstall it. Add it to
    `linux_vdi_removed_packages` to uninstall it.
  EOT
  type = map(object({
    description = optional(string, "")
    packages    = optional(list(string), [])
    apt_repository = optional(object({
      uri          = string
      distribution = string
      components   = optional(list(string), ["main"])
      gpg_key      = optional(string)
    }))
    deb_packages = optional(map(object({
      uri    = string
      sha256 = string
    })), {})
    users = optional(list(string), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.linux_vdi_software) : can(regex("^[a-z]([a-z0-9-]{0,38}[a-z0-9])?$", k))])
    error_message = "linux_vdi_software keys must be lowercase, start with a letter, contain only [a-z0-9-] and be at most 40 characters."
  }

  validation {
    condition     = alltrue([for b in values(var.linux_vdi_software) : length(b.packages) + length(b.deb_packages) > 0])
    error_message = "Each linux_vdi_software bundle must define at least one entry in `packages` or `deb_packages`."
  }

  validation {
    condition = alltrue(flatten([
      for b in values(var.linux_vdi_software) : [for d in values(b.deb_packages) : can(regex("^[a-f0-9]{64}$", lower(d.sha256)))]
    ]))
    error_message = "Each deb_packages entry must have a valid 64-character hex SHA256 checksum."
  }
}

variable "linux_vdi_removed_packages" {
  description = "APT package names that OS Config must ensure are REMOVED from all Linux VDIs (use this to uninstall software previously deployed via `linux_vdi_software`)."
  type        = list(string)
  default     = []
}

variable "linux_vdi_proxy_config" {
  description = <<-EOT
    Optional outbound HTTP/HTTPS forward proxy configuration for Linux VDIs.
    When provided, OS Config configures APT (/etc/apt/apt.conf.d/99proxy) and
    Chromium managed policies (/etc/chromium/policies/managed/proxy.json)
    to route traffic through the specified proxy. Leave null when using Cloud NAT
    or direct egress.
  EOT
  type = object({
    http_proxy  = string
    https_proxy = optional(string)
    bypass_list = optional(string, "*.google.com*;*.googleapis.com")
  })
  default = null
}
