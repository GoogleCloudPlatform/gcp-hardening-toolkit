
output "custom_constraint_name" {
  description = "The name of the custom constraint."
  value       = google_org_policy_custom_constraint.disallow_external_scripts.name
}

output "policy_name" {
  description = "The name of the policy."
  value       = google_org_policy_policy.enforce_disallow_external_scripts.name
}
