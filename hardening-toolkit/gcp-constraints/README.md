# GCP Constraints

This Terraform module applies a set of custom constraints to a GCP organization, folder, or project.

## Available Constraints

-   **DNSSEC Enabled:** Enforces that all new Cloud DNS managed zones have DNSSEC enabled.
-   **GKE Network Tags:** Enforces that all new GKE clusters have network tags.
-   **Cloud SQL External Scripts Disabled:** Enforces that Cloud SQL instances do not have the 'external scripts enabled' flag set.
-   **Cloud Storage Bucket Versioning:** Enforces that all new Cloud Storage buckets have object versioning enabled.
-   **VPC Private Google Access:** Enforces that all new VPC network subnets have private Google access enabled.

## Usage

```hcl
module "gcp_constraints" {
  source = "github.com/your-org/your-repo/gem-gcp-constraints"

  parent = "organizations/123456789012"

  enable_dns_constraint                       = true
  enable_gke_constraint                       = true
  enable_sql_constraint                       = true
  enable_storage_constraint                   = true
  enable_vpc_private_google_access_constraint = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| parent | The parent resource to attach the policy to. Must be in the format 'organizations/{organization\_id}', 'folders/{folder\_id}', or 'projects/{project\_id}'. | string | n/a | yes |
| enable\_dns\_constraint | Enable the DNSSEC custom constraint. | bool | `true` | no |
| enable\_gke\_constraint | Enable the GKE network tags custom constraint. | bool | `true` | no |
| enable\_sql\_constraint | Enable the Cloud SQL 'external scripts enabled' custom constraint. | bool | `true` | no |
| enable\_storage\_constraint | Enable the Cloud Storage bucket versioning custom constraint. | bool | `true` | no |
| enable\_vpc\_private\_google\_access\_constraint | Enable the VPC private Google access custom constraint. | bool | `true` | no |