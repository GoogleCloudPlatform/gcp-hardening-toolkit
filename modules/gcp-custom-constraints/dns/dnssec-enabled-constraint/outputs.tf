
output "custom_constraint_name" {
  description = "The name of the custom constraint."
  value       = google_org_policy_custom_constraint.dnssec_enabled.name
}

output "policy_name" {
  description = "The name of the policy."
  value       = google_org_policy_policy.enforce_dnssec_enabled.name
}
