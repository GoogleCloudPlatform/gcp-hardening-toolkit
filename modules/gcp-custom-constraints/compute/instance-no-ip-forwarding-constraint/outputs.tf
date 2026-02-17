output "custom_constraint_name" {
  description = "The name of the custom constraint preventing IP forwarding."
  value       = google_org_policy_custom_constraint.instance_no_ip_forwarding.name
}

output "policy_name" {
  description = "The name of the policy preventing IP forwarding."
  value       = google_org_policy_policy.enforce_instance_no_ip_forwarding.name
}
