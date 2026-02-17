output "custom_constraint_name" {
  description = "The name of the custom constraint preventing default service account usage."
  value       = google_org_policy_custom_constraint.instance_no_default_sa.name
}

output "policy_name" {
  description = "The name of the policy preventing default service account usage."
  value       = google_org_policy_policy.enforce_instance_no_default_sa.name
}
