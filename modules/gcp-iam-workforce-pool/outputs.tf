output "custom_constraint_name" {
  description = "The full name of the custom constraint created."
  value       = google_org_policy_custom_constraint.lock_workforce_pools.name
}

output "policy_name" {
  description = "The full name of the organization policy created."
  value       = google_org_policy_policy.enforce_lock_workforce_pools.name
}
