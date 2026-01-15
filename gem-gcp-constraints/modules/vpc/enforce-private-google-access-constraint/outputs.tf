output "custom_constraint_name" {
  description = "The name of the custom constraint for private Google access."
  value       = google_org_policy_custom_constraint.private_google_access.name
}

output "policy_name" {
  description = "The name of the policy for private Google access."
  value       = google_org_policy_policy.enforce_private_google_access.name
}
