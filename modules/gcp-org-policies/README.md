# GCP Organization Policies Module

This module enforces a set of built-in Google Cloud organization policy constraints at the organization or folder level, using [`terraform-google-modules/org-policy`](https://registry.terraform.io/modules/terraform-google-modules/org-policy/google).

By default it enforces every supported policy (15 boolean and 9 list constraints). Callers can optionally enforce only a subset with `boolean_policies` and `list_policies`, which lets each blueprint apply only the controls it needs (for example, one section of a compliance benchmark at a time).

## Usage

### Enforce all supported policies (default)

```hcl
module "org_policies" {
  source = "../../modules/gcp-org-policies"

  organization_id  = "123456789012"
  domains_to_allow = ["C0xxxxxxx"]
}
```

### Enforce a subset of policies

```hcl
module "org_policies" {
  source = "../../modules/gcp-org-policies"

  organization_id  = "123456789012"
  domains_to_allow = ["C0xxxxxxx"]

  boolean_policies = [
    "iam.disableServiceAccountKeyCreation",
    "iam.disableServiceAccountKeyUpload",
    "iam.automaticIamGrantsForDefaultServiceAccounts",
  ]

  list_policies = [
    "iam.allowedPolicyMemberDomains",
  ]
}
```

Set `parent_folder = "folders/<FOLDER_ID>"` to apply the policies to a folder instead of the organization.

Use `terraform apply -parallelism=1` when deploying organization policies to avoid transient 409 errors from the Organization Policy API.

## Supported policies

Names are given without the `constraints/` prefix. The CIS column lists the related [CIS Google Cloud Platform Foundation Benchmark v3.0.0](https://www.cisecurity.org/benchmark/google_cloud_computing_platform) recommendation, for reference.

### Boolean constraints (`boolean_policies`)

| Constraint | Effect | CIS |
|---|---|---|
| `compute.disableNestedVirtualization` | Disables nested virtualization on VMs. | — |
| `compute.disableVpcExternalIpv6` | Disables the creation of subnets with external IPv6 ranges. | — |
| `compute.setNewProjectDefaultToZonalDNSOnly` | Sets internal DNS to zonal-only for new projects. | — |
| `compute.disableSerialPortAccess` | Disables serial port access to VMs. | 4.5 |
| `compute.skipDefaultNetworkCreation` | Skips the creation of the `default` network in new projects. | 3.1 |
| `compute.restrictXpnProjectLienRemoval` | Restricts removal of Shared VPC host project liens. | — |
| `compute.requireOsLogin` | Requires OS Login on VMs. | 4.4 |
| `sql.restrictPublicIp` | Prevents public IP addresses on Cloud SQL instances. | 6.6 |
| `sql.restrictAuthorizedNetworks` | Prevents authorized networks on Cloud SQL instances. | 6.5 |
| `iam.disableServiceAccountKeyCreation` | Prevents the creation of service account keys. | 1.4 |
| `iam.disableServiceAccountKeyUpload` | Prevents uploading external service account keys. | 1.4 |
| `iam.automaticIamGrantsForDefaultServiceAccounts` | Prevents the automatic Editor grant to default service accounts. | 1.5 |
| `storage.uniformBucketLevelAccess` | Requires uniform bucket-level access on Cloud Storage buckets. | 5.2 |
| `storage.publicAccessPrevention` | Enforces public access prevention on Cloud Storage buckets. | 5.1 |
| `compute.requireShieldedVm` | Requires Shielded VMs. | 4.8 |

### List constraints (`list_policies`)

| Constraint | Effect | Configured by | CIS |
|---|---|---|---|
| `compute.vmExternalIpAccess` | Restricts which VMs can have external IPs. | `allowed_external_ips` | 4.9 |
| `compute.restrictProtocolForwardingCreationForTypes` | Allows only `INTERNAL` protocol forwarding. | — | — |
| `iam.allowedPolicyMemberDomains` | Restricts IAM members to the allowed domains. Only enforced when `domains_to_allow` is not empty. | `domains_to_allow` | 1.1 |
| `compute.trustedImageProjects` | Restricts the projects VM images can come from. | `trusted_image_projects` | — |
| `essentialcontacts.allowedContactDomains` | Restricts Essential Contacts to the allowed domains. | `essential_contacts_domains_to_allow` | — |
| `gcp.resourceLocations` | Restricts the locations where resources can be created. | `allowed_resource_locations` | — |
| `compute.restrictNonConfidentialComputing` | Requires Confidential Computing for VMs. | `allowed_non_confidential_computing` | 4.11 |
| `gcp.restrictNonCmekServices` | Requires CMEK for the listed services. | `denied_non_cmek_services` | — |
| `compute.requireVpcFlowLogs` | Requires VPC Flow Logs on subnets. | `allowed_vpc_flow_logs_settings` | 3.8 |

An unknown name in `boolean_policies` or `list_policies` fails the plan with an explicit error, so a typo cannot silently leave a control disabled.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `organization_id` | The organization ID where the policies will be applied. | `string` | n/a | yes |
| `parent_folder` | The folder (`folders/<ID>`) where the policies will be applied. When set, it takes precedence over `organization_id`. | `string` | `""` | no |
| `boolean_policies` | Boolean constraints to enforce. `null` enforces all supported boolean constraints. | `list(string)` | `null` | no |
| `list_policies` | List constraints to enforce. `null` enforces all supported list constraints. | `list(string)` | `null` | no |
| `domains_to_allow` | Domains (Cloud Identity customer IDs) allowed for `iam.allowedPolicyMemberDomains`. | `list(string)` | `[]` | no |
| `allowed_external_ips` | VMs allowed to have external IPs. | `list(string)` | `[]` | no |
| `essential_contacts_domains_to_allow` | Domains allowed for Essential Contacts. | `list(string)` | `[]` | no |
| `allowed_resource_locations` | Locations where resources can be created. | `list(string)` | `["us-east4", "us-central1"]` | no |
| `trusted_image_projects` | Projects allowed as VM image sources. | `list(string)` | `[]` | no |
| `allowed_non_confidential_computing` | VM types allowed without Confidential Computing. | `list(string)` | `[]` | no |
| `denied_non_cmek_services` | Services that must use CMEK. | `list(string)` | `[]` | no |
| `allowed_vpc_flow_logs_settings` | Allowed VPC Flow Logs settings (`ESSENTIAL`, `LIGHT`, `COMPREHENSIVE`). | `list(string)` | `["ESSENTIAL", "LIGHT", "COMPREHENSIVE"]` | no |

## Outputs

| Name | Description |
|------|-------------|
| `enforced_boolean_policies` | Boolean constraints enforced by this module. |
| `enforced_list_policies` | List constraints enforced by this module. |

## Upgrading existing deployments

The list constraint module blocks now use `count`, which changes their addresses in the Terraform state (for example, `module.org_vm_external_ip_access` becomes `module.org_vm_external_ip_access[0]`). The module includes `moved` blocks for these addresses, so `terraform plan` on an existing deployment shows the policies as moved, not destroyed and recreated. No manual `terraform state mv` is needed.

## Testing

The `tests/` directory contains `terraform test` tests that run against a mocked Google provider, so they need no credentials. They require Terraform >= 1.7; the module itself supports Terraform >= 1.3.

```bash
cd modules/gcp-org-policies
terraform init
terraform test
```

The tests check that:

- without `boolean_policies` / `list_policies`, all 15 + 9 policies are enforced (backwards compatibility);
- a subset enforces only the selected policies;
- an unknown policy name fails the plan.
