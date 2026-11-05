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
# OUTPUT DEFINITIONS: Enterprise Compute Engine VDI
# ==============================================================================

output "vdi_network_name" {
  description = "The VPC network name hosting the VDI infrastructure."
  value       = var.network_name
}

output "vdi_subnetwork_name" {
  description = "The subnetwork name hosting the VDI infrastructure."
  value       = var.subnetwork_name
}


# ------------------------------------------------------------------------------
# Linux Developer IAP VDI Outputs (1:1 Bindings)
# ------------------------------------------------------------------------------

output "linux_vdi_instances" {
  description = "Map of 1:1 assigned Linux VDI VM instances and their connection details."
  value = {
    for instance_name, user_info in local.linux_vdi_users_map :
    instance_name => {
      user_identity          = user_info.email
      iam_member             = user_info.iam_member
      internal_ip            = try(google_compute_instance.linux_vdi[instance_name].network_interface[0].network_ip, null)
      ssh_command            = "gcloud compute ssh ${instance_name} --zone=${var.zone} --tunnel-through-iap --project=${var.project_id}"
      iap_rdp_tunnel_command = "gcloud compute start-iap-tunnel ${instance_name} 3389 --local-host-port=localhost:3389 --zone=${var.zone} --project=${var.project_id}"
      rdp_username           = replace(lower(user_info.email), "/[^a-z0-9]+/", "_")
    }
  }
}

# ------------------------------------------------------------------------------
# Windows Developer IAP VDI Outputs (1:1 Bindings)
# ------------------------------------------------------------------------------

output "windows_vdi_instances" {
  description = "Map of 1:1 assigned Windows VDI VM instances and their connection details."
  value = {
    for instance_name, user_info in local.windows_vdi_users_map :
    instance_name => {
      user_identity          = user_info.email
      iam_member             = user_info.iam_member
      internal_ip            = try(google_compute_instance.windows_vdi[instance_name].network_interface[0].network_ip, null)
      iap_rdp_tunnel_command = "gcloud compute start-iap-tunnel ${instance_name} 3389 --local-host-port=localhost:3389 --zone=${var.zone} --project=${var.project_id}"
      reset_password_command = "gcloud compute reset-windows-password ${instance_name} --zone=${var.zone} --project=${var.project_id}"
    }
  }
}
