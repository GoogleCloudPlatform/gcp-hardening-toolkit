output "custom_constraint_name" {
  description = "The name of the custom constraint for Dataproc cluster CMEK."
  value       = google_org_policy_custom_constraint.dataproc_cmek.name
}

output "policy_name" {
  description = "The name of the policy for Dataproc cluster CMEK."
  value       = google_org_policy_policy.enforce_dataproc_cmek.name
}
