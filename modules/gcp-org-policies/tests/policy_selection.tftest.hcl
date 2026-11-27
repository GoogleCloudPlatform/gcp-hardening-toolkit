# Tests for the policy selection feature (var.boolean_policies / var.list_policies).
# They run against a mocked Google provider, so no GCP credentials are needed:
#
#   terraform init
#   terraform test
#
# Requires Terraform >= 1.7 (mock providers). The module itself still supports >= 1.3.

mock_provider "google" {}

variables {
  organization_id  = "123456789012"
  domains_to_allow = ["example.com"]
}

# Callers that do not set the new variables (e.g. gcp-compliance-soc2) must keep
# getting every policy, exactly as before.
run "defaults_enforce_all_policies" {
  command = plan

  assert {
    condition     = length(module.organization_policies_type_boolean) == 15
    error_message = "All 15 boolean policies should be enforced by default."
  }

  assert {
    condition     = length(output.enforced_list_policies) == 9
    error_message = "All 9 list policies should be enforced by default."
  }

  assert {
    condition     = length(module.org_vm_external_ip_access) == 1 && length(module.require_vpc_flow_logs) == 1
    error_message = "List policy modules should be created by default."
  }
}

# The CIS blueprint selects only the IAM policies (CIS 1.1, 1.4 and 1.5).
run "subset_enforces_only_selected_policies" {
  command = plan

  variables {
    boolean_policies = [
      "iam.disableServiceAccountKeyCreation",
      "iam.disableServiceAccountKeyUpload",
      "iam.automaticIamGrantsForDefaultServiceAccounts",
    ]
    list_policies = ["iam.allowedPolicyMemberDomains"]
  }

  assert {
    condition     = length(module.organization_policies_type_boolean) == 3
    error_message = "Only the 3 selected boolean policies should be enforced."
  }

  assert {
    condition     = length(module.org_domain_restricted_sharing) == 1
    error_message = "The selected domain restricted sharing policy should be enforced."
  }

  assert {
    condition     = length(module.org_vm_external_ip_access) == 0 && length(module.resource_location_restriction) == 0
    error_message = "List policies that were not selected must not be enforced."
  }

  assert {
    condition     = output.enforced_list_policies == ["iam.allowedPolicyMemberDomains"]
    error_message = "enforced_list_policies should only report the selected policy."
  }
}

# A misspelled name must fail the plan instead of silently skipping a control.
run "unknown_policy_name_fails" {
  command = plan

  variables {
    boolean_policies = ["iam.disableServiceAcountKeyCreation"]
  }

  expect_failures = [
    output.enforced_boolean_policies,
  ]
}
