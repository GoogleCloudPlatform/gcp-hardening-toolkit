output "enabled_policies" {
  description = "List of enabled organization policies"
  value = var.enabled ? [
    "iam.disableServiceAccountKeyCreation",
    "iam.automaticIamGrantsForDefaultServiceAccounts",
    "iam.allowedPolicyMemberDomains",
    "compute.vmExternalIpAccess",
    "compute.requireOsLogin",
    "compute.requireShieldedVm",
    "sql.restrictPublicIp"
  ] : []
}
