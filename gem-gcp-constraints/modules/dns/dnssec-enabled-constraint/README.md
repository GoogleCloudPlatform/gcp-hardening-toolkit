
# DNSSEC Enabled Custom Constraint

This module creates a custom organization policy constraint that ensures DNSSEC is enabled for all Cloud DNS managed zones.

## Usage

```terraform
module "dnssec_enabled_constraint" {
  source = "github.com/your-repo/gem-gcp-constraints/modules/dns/dnssec-enabled-constraint"
  parent = "organizations/{your_organization_id}"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| parent | The parent resource to attach the policy to. Must be in the format 'organizations/{organization_id}', 'folders/{folder_id}', or 'projects/{project_id}'. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| custom_constraint_name | The name of the custom constraint. |
| policy_name | The name of the policy. |

## Validation

To validate that the custom constraint is working, try to create a Cloud DNS managed zone with DNSSEC disabled. The operation should fail with a `Constraint violated` error.

You can use the following `gcloud` command to try and create a managed zone with DNSSEC disabled:

```bash
gcloud dns managed-zones create my-test-zone \
  --description="Test zone" \
  --dns-name="my-test-zone.example.com." \
  --dnssec-state=off
```
