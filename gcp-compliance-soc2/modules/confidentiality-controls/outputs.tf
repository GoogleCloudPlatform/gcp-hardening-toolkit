output "enabled_policies" {
  description = "List of enabled organization policies"
  value = var.enabled ? [
    "storage.uniformBucketLevelAccess",
    "storage.publicAccessPrevention",
    "gcp.restrictNonCmekServices",
    "compute.restrictVpcPeering"
  ] : []
}
