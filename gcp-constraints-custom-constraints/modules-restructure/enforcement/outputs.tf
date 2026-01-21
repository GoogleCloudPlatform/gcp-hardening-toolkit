output "applied_policies" {
  description = "List of the full resource names for the applied organization policies."
  value       = [for p in google_org_policy_policy.enforce_constraints : p.name]
}

output "enforcement_count" {
  description = "The number of policies successfully enforced."
  value       = length(google_org_policy_policy.enforce_constraints)
}
