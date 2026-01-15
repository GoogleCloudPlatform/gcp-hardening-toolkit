# Enforce Private Google Access Constraint

This Terraform module creates a custom organization policy constraint to enforce that all VPC network subnets have private Google access enabled.

## Usage

```hcl
module "enforce_private_google_access" {
  source = "./modules/vpc/enforce-private-google-access-constraint"

  parent = "organizations/123456789012"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| parent | The parent resource to attach the policy to. Must be in the format 'organizations/{organization\_id}'. | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| custom\_constraint | The custom constraint for private Google access. |
