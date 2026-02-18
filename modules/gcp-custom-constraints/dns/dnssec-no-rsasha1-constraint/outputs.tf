output "custom_constraint_name" {
  description = "The name of the custom constraint preventing RSASHA1 DNSSEC algorithm."
  value       = google_org_policy_custom_constraint.dnssec_no_rsasha1.name
}

output "policy_name" {
  description = "The name of the policy preventing RSASHA1 DNSSEC algorithm."
  value       = google_org_policy_policy.enforce_dnssec_no_rsasha1.name
}
