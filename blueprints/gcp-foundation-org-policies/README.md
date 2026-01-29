
# Organization Policies Terraform Module

This Terraform module manages GCP organization policies.

## Usage

```hcl
module "org_policies" {
  source = "./gcp-foundation-org-policies"

  organization_id = "your-organization-id"
  parent_folder   = "your-folder-id"

  create_access_context_manager_access_policy = true

  domains_to_allow = ["example.com"]
  allowed_external_ips = ["1.2.3.4"]
  essential_contacts_domains_to_allow = ["example.com"]
  allowed_resource_locations = ["in:us-east4", "in:us-central1"]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `organization_id` | The organization ID where the policies will be applied. | `string` | n/a | yes |
| `parent_folder` | The folder ID where the policies will be applied. | `string` | `""` | no |
| `create_access_context_manager_access_policy` | Create an access context manager access policy. | `bool` | `false` | no |
| `domains_to_allow` | The list of domains to allow for domain restricted sharing. | `list(string)` | `[]` | no |
| `allowed_external_ips` | The list of allowed VMs to get public IPs. | `list(string)` | `[]` | no |
| `essential_contacts_domains_to_allow` | The list of allowed domains for essential contacts. | `list(string)` | `[]` | no |
| `allowed_resource_locations` | The list of allowed resource locations. | `list(string)` | `["us-east4", "us-central1"]` | no |

## Outputs

This module has no outputs.

## Policies

- **Define allowed external IPs for VM instances:** By default, this module denies all external IPs for VM instances. You can override this by setting the `allowed_external_ips` variable, make sure enforce is not set.
- **Domain Restricted Sharing:** This policy restricts the domains that can be used for sharing resources. You can specify the allowed domains by using the `domains_to_allow` variable.
- **Define trusted image projects for VM creations:** This policy restricts the projects from which VM images can be used. By default, it is set to `approved-projects-ids`.
- **Domain Restricted Contacts:** This policy restricts the domains that can be used for essential contacts. You can specify the allowed domains by using the `essential_contacts_domains_to_allow` variable.
- **Resource Location Restriction:** This policy restricts the locations where resources can be created. You can specify the allowed locations by using the `allowed_resource_locations` variable.
- **Restrict which services may create resources without CMEK:** This policy denies the creation of resources without CMEK for the specified services.

## Resources

- `google_access_context_manager_access_policy.access_policy`: Creates an access context manager access policy.
