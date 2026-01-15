# Terraform Google IAM Workforce Pool Constraint

This module creates and enforces a custom Google Cloud Organization Policy to restrict which IAM roles can be granted to Workforce Identity Pools.

## Usage

Provide the `organization_id` and a list of allowed role prefixes. The module will create the custom constraint and the corresponding policy to enforce it.

```hcl
module "restrict_workforce_pool_roles" {
  source = "./modules/iam-workforce-pool-constraint"

  organization_id = "123456789012"

  allowed_roles_prefixes = [
    "roles/iap.webServiceUser",
    "roles/cloudsql.client"
  ]
  
  display_name = "Corp Workforce Pool Role Restrictions"
}