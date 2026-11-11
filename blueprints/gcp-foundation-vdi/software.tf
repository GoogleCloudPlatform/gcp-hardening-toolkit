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
# 6. ADMIN-MANAGED VDI SOFTWARE (OS CONFIG / VM MANAGER)
# ==============================================================================
# VDI users have no sudo (roles/compute.osLogin), so software is installed by
# administrators through Terraform:
#
#   tfvars `linux_vdi_software` -> PR -> pipeline apply -> OS Config agent on
#   each VDI installs the packages (as root) and keeps them installed.
#
# - One OS policy assignment per bundle, so a broken bundle does not block others.
# - Bundles target all Linux VDIs (label vdi-os=linux) or specific users'
#   VDIs (label vdi-name=<vm-name>). Labels are set in main.tf.
# - The VM startup script is intentionally NOT used for software: changing
#   `metadata_startup_script` force-replaces every VDI (and its boot disk).
# - Compliance per VM: Console > Compute Engine > VM Manager > OS policies.
# ==============================================================================

locals {
  # email (lowercase) -> Linux VDI VM name
  linux_vdi_email_to_vm = { for vm, u in local.linux_vdi_users_map : lower(u.email) => vm }

  linux_vdi_software_bundles = length(local.linux_vdi_users_map) > 0 ? {
    for key, b in var.linux_vdi_software : key => {
      description    = b.description != "" ? b.description : "VDI software bundle: ${key}"
      apt_repository = b.apt_repository
      users          = b.users
      target_vms     = [for e in b.users : lookup(local.linux_vdi_email_to_vm, lower(trimprefix(e, "user:")), null)]

      # OS Config resource IDs: [a-z0-9-], start with a letter, <= 63 chars, unique per policy.
      packages = {
        for p in distinct(b.packages) :
        "apt-${substr(trim(replace(lower(p), "/[^a-z0-9]+/", "-"), "-"), 0, 58)}" => p
      }
      deb_packages = {
        for name, d in b.deb_packages :
        "deb-${substr(trim(replace(lower(name), "/[^a-z0-9]+/", "-"), "-"), 0, 58)}" => d
      }
    }
  } : {}

  linux_vdi_removed_packages = length(local.linux_vdi_users_map) > 0 ? {
    for p in distinct(var.linux_vdi_removed_packages) :
    "rm-${substr(trim(replace(lower(p), "/[^a-z0-9]+/", "-"), "-"), 0, 59)}" => p
  } : {}

  linux_vdi_all_managed_packages = distinct(flatten([for b in values(var.linux_vdi_software) : b.packages]))
}

# 6.1 One OS policy assignment per software bundle
resource "google_os_config_os_policy_assignment" "linux_vdi_software" {
  for_each = local.linux_vdi_software_bundles

  project            = var.project_id
  location           = var.zone
  name               = "vdi-linux-sw-${each.key}"
  description        = each.value.description
  skip_await_rollout = true

  instance_filter {
    all = false

    # Empty `users` -> all Linux VDIs; otherwise only the listed users' VDIs
    # (multiple inclusion_labels blocks are OR'ed).
    dynamic "inclusion_labels" {
      for_each = length(each.value.users) == 0 ? [tomap({ "vdi-os" = "linux" })] : [for vm in each.value.target_vms : tomap({ "vdi-name" = vm })]
      content {
        labels = inclusion_labels.value
      }
    }
  }

  os_policies {
    id          = "vdi-linux-sw-${each.key}"
    description = each.value.description
    mode        = "ENFORCEMENT"

    resource_groups {
      # 0. Optional APT Proxy (ensures apt can download packages when behind an explicit proxy)
      dynamic "resources" {
        for_each = var.linux_vdi_proxy_config != null ? [var.linux_vdi_proxy_config] : []
        content {
          id = "apt-proxy"
          exec {
            validate {
              script      = <<-EOF
                FILE="/etc/apt/apt.conf.d/99proxy"
                if [ -f "$FILE" ] && grep -q -F "${resources.value.http_proxy}" "$FILE"; then
                  exit 100 # Compliant
                else
                  exit 101 # Non-compliant
                fi
              EOF
              interpreter = "SHELL"
            }
            enforce {
              script      = <<-EOF
                cat << 'EOT' > /etc/apt/apt.conf.d/99proxy
Acquire::http::Proxy "${resources.value.http_proxy}";
Acquire::https::Proxy "${coalesce(resources.value.https_proxy, resources.value.http_proxy)}";
EOT
                exit 100
              EOF
              interpreter = "SHELL"
            }
          }
        }
      }

      # Resources are applied in order: (optional) APT Proxy -> repository -> APT packages -> .deb files.
      dynamic "resources" {
        for_each = each.value.apt_repository != null ? [each.value.apt_repository] : []
        content {
          id = "repo"
          repository {
            apt {
              archive_type = "DEB"
              uri          = resources.value.uri
              distribution = resources.value.distribution
              components   = resources.value.components
              gpg_key      = resources.value.gpg_key
            }
          }
        }
      }

      dynamic "resources" {
        for_each = each.value.packages
        content {
          id = resources.key
          pkg {
            desired_state = "INSTALLED"
            apt {
              name = resources.value
            }
          }
        }
      }

      dynamic "resources" {
        for_each = each.value.deb_packages
        content {
          id = resources.key
          pkg {
            desired_state = "INSTALLED"
            deb {
              pull_deps = true
              source {
                remote {
                  uri             = resources.value.uri
                  sha256_checksum = lower(resources.value.sha256)
                }
              }
            }
          }
        }
      }

      dynamic "resources" {
        for_each = contains(values(each.value.packages), "xrdp") ? [1] : []
        content {
          id = "configure-xrdp"
          exec {
            validate {
              script      = <<-EOF
                VDI_USER=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/vdi-username -s)
                if [ -z "$VDI_USER" ]; then
                  exit 100
                fi

                if grep -q "username=$VDI_USER" /etc/xrdp/xrdp.ini && ! grep -q "^-e" /etc/pam.d/xrdp-sesman && grep -q "pam_permit.so" /etc/pam.d/xrdp-sesman; then
                  exit 100
                else
                  exit 101
                fi
              EOF
              interpreter = "SHELL"
            }
            enforce {
              script      = <<-EOF
                VDI_USER=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/vdi-username -s)
                if [ -z "$VDI_USER" ]; then
                  exit 1
                fi

                awk '
                /^\[/ { in_section = 0 }
                /^\[Xorg\]/ || /^\[neutrinordp-any\]/ || /^\[Xvnc\]/ || /^\[vnc-any\]/ || /^\[xvnc-any\]/ || /^\[rdp-any\]/ { in_section = 1 }
                !in_section { print }
                ' /etc/xrdp/xrdp.ini > /etc/xrdp/xrdp.ini.tmp && mv /etc/xrdp/xrdp.ini.tmp /etc/xrdp/xrdp.ini

                cat <<EOT >> /etc/xrdp/xrdp.ini

[Xorg]
name=Xorg
lib=libxup.so
username=$VDI_USER
password=
ip=127.0.0.1
port=-1
code=20
EOT

                cat <<EOT > /etc/pam.d/xrdp-sesman
auth required pam_permit.so
account required pam_permit.so
session required pam_permit.so
EOT

                systemctl restart xrdp xrdp-sesman
                exit 100
              EOF
              interpreter = "SHELL"
            }
          }
        }
      }
    }
  }

  rollout {
    min_wait_duration = "60s"
    disruption_budget {
      percent = 100
    }
  }

  lifecycle {
    precondition {
      condition     = alltrue([for vm in each.value.target_vms : vm != null])
      error_message = "linux_vdi_software[\"${each.key}\"].users contains an email that is not in linux_vdi_users."
    }
  }

  depends_on = [
    google_project_service.vdi_apis,
    google_compute_instance.linux_vdi,
  ]
}

# 6.2 Explicit uninstall list (removing a package from a bundle does not uninstall it)
resource "google_os_config_os_policy_assignment" "linux_vdi_removed_software" {
  count = length(local.linux_vdi_removed_packages) > 0 ? 1 : 0

  project            = var.project_id
  location           = var.zone
  name               = "vdi-linux-sw-removed"
  description        = "Packages that must NOT be present on Linux VDIs. Managed by Terraform."
  skip_await_rollout = true

  instance_filter {
    all = false
    inclusion_labels {
      labels = { "vdi-os" = "linux" }
    }
  }

  os_policies {
    id          = "vdi-linux-sw-removed"
    description = "Packages that must NOT be present on Linux VDIs."
    mode        = "ENFORCEMENT"

    resource_groups {
      dynamic "resources" {
        for_each = local.linux_vdi_removed_packages
        content {
          id = resources.key
          pkg {
            desired_state = "REMOVED"
            apt {
              name = resources.value
            }
          }
        }
      }
    }
  }

  rollout {
    min_wait_duration = "60s"
    disruption_budget {
      percent = 100
    }
  }

  lifecycle {
    precondition {
      condition     = length(setintersection(toset(var.linux_vdi_removed_packages), toset(local.linux_vdi_all_managed_packages))) == 0
      error_message = "A package cannot be both in linux_vdi_software and linux_vdi_removed_packages (OS Config would flip-flop)."
    }
  }

  depends_on = [
    google_project_service.vdi_apis,
    google_compute_instance.linux_vdi,
  ]
}

# 6.3 Optional Chromium Proxy Configuration
resource "google_os_config_os_policy_assignment" "linux_vdi_chromium_config" {
  count = length(local.linux_vdi_users_map) > 0 && var.linux_vdi_proxy_config != null ? 1 : 0

  project            = var.project_id
  location           = var.zone
  name               = "vdi-linux-chromium-config"
  description        = "Configures Chromium proxy settings for Linux VDIs."
  skip_await_rollout = true

  instance_filter {
    all = false
    inclusion_labels {
      labels = { "vdi-os" = "linux" }
    }
  }

  os_policies {
    id          = "chromium-proxy-policy"
    description = "Enforces Chromium proxy configuration"
    mode        = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "chromium-proxy-json"
        exec {
          validate {
            script      = <<-EOF
              FILE="/etc/chromium/policies/managed/proxy.json"
              if [ -f "$FILE" ] && grep -q -F "${var.linux_vdi_proxy_config.http_proxy}" "$FILE" && grep -q -F "${var.linux_vdi_proxy_config.bypass_list}" "$FILE"; then
                exit 100 # Compliant
              else
                exit 101 # Non-compliant, enforcement needed
              fi
            EOF
            interpreter = "SHELL"
          }
          enforce {
            script      = <<-EOF
              mkdir -p /etc/chromium/policies/managed/
              cat << 'EOT' > /etc/chromium/policies/managed/proxy.json
{
  "ProxyMode": "fixed_servers",
  "ProxyServer": "${var.linux_vdi_proxy_config.http_proxy};${coalesce(var.linux_vdi_proxy_config.https_proxy, var.linux_vdi_proxy_config.http_proxy)}",
  "ProxyBypassList": "${var.linux_vdi_proxy_config.bypass_list}"
}
EOT
              exit 100
            EOF
            interpreter = "SHELL"
          }
        }
      }
    }
  }

  rollout {
    min_wait_duration = "60s"
    disruption_budget {
      percent = 100
    }
  }

  depends_on = [
    google_project_service.vdi_apis,
    google_compute_instance.linux_vdi,
  ]
}
