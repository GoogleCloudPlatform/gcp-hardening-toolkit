# Prevent Public IAM Bindings (allUsers, allAuthenticatedUsers)

This module creates a custom organization policy constraint that prevents the inclusion of `allUsers` or `allAuthenticatedUsers` in IAM allow policies. This is a critical security control to prevent accidental or intentional public exposure of resources.

## Security Rationale

**Why this constraint matters:**
- **Prevents Public Data Exposure**: Blocks sharing resources with the entire internet.
- **Enforces Principle of Least Privilege**: Ensures only identified principals (users, groups, service accounts) have access.
- **Compliance**: Required by almost all security frameworks (CIS, SOC2, HIPAA, PCI-DSS).
- **Global Control**: Using `iam.googleapis.com/AllowPolicy` provides a unified way to block public access across many GCP services that use standard IAM policies (e.g., Cloud Functions, Pub/Sub, Artifact Registry).

## How It Works

The constraint monitors modifications to IAM allow policies and blocks any request that attempts to grant permissions to `allUsers` or `allAuthenticatedUsers`.

**Technical Details:**
- **Resource Type**: `iam.googleapis.com/AllowPolicy`
- **Action Type**: `DENY`
- **Method Types**: `CREATE`, `UPDATE`
- **Condition**: `resource.bindings.exists(binding, binding.members.exists(member, MemberSubjectMatches(member, ['allUsers', 'allAuthenticatedUsers'])))`

## Usage

This module is called automatically by the root `main.tf` when the following variable is enabled:

```hcl
enable_iam_no_public_bindings_constraint = true
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `parent` | The parent resource to attach the policy to. Format: `organizations/{id}`, `folders/{id}`, or `projects/{id}` | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `custom_constraint_name` | The name of the custom constraint |
| `policy_name` | The name of the organization policy |

## Validation

### Test with gcloud (should FAIL):

Try to grant the `roles/viewer` role to `allUsers` on a resource:

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="allUsers" \
    --role="roles/viewer"
```

**Expected error:**
```
ERROR: (gcloud.projects.add-iam-policy-binding) Precondition check failed.
- Constraint custom.iamNoPublicBindings violated
```

### Terraform-based Testing

For automated validation, use the centralized test suite:

1. **Compliant Test**:
   ```bash
   cd ../../../tests/compliant
   terraform apply -target=google_artifact_registry_repository_iam_member.compliant_iam_binding
   ```

2. **Non-Compliant Test**:
   ```bash
   cd ../../../tests/non-compliant
   terraform apply -target=google_artifact_registry_repository_iam_member.violating_iam_binding
   ```
