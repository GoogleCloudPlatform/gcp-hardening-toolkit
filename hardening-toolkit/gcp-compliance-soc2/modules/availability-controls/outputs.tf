output "enabled_policies" {
  description = "List of enabled organization policies"
  value = var.enabled ? [
    "gcp.resourceLocations",
    "sql.restrictAuthorizedNetworks"
  ] : []
}
