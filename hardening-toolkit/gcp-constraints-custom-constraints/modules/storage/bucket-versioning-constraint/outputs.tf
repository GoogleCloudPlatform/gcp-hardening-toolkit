output "custom_constraint_name" {
  description = "The name of the custom constraint for bucket versioning."
  value       = google_org_policy_custom_constraint.bucket_versioning.name
}

output "policy_name" {
  description = "The name of the policy for bucket versioning."
  value       = google_org_policy_policy.enforce_bucket_versioning.name
}
