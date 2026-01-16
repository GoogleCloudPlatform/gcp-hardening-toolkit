
output "custom_constraint_name" {
  description = "The name of the custom constraint for custom mode VPC."
  value       = google_org_policy_custom_constraint.custom_mode_vpc.name
}

output "policy_name" {
  description = "The name of the policy for custom mode VPC."
  value       = google_org_policy_policy.enforce_custom_mode_vpc.name
}
