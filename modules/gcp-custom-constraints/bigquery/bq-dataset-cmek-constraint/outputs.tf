output "custom_constraint_name" {
  description = "The name of the custom constraint for BigQuery dataset CMEK."
  value       = google_org_policy_custom_constraint.bq_dataset_cmek.name
}

output "policy_name" {
  description = "The name of the policy for BigQuery dataset CMEK."
  value       = google_org_policy_policy.enforce_bq_dataset_cmek.name
}
