# Enforce Custom Mode VPC Constraint

This Terraform module creates a custom organization policy constraint to enforce that all VPC networks are created in custom mode.

## Usage

```hcl
module "enforce_custom_mode_vpc_constraint" {
  source = "./modules/vpc/enforce-custom-mode-vpc-constraint"

  parent = "organizations/123456789012"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| parent | The parent resource to attach the policy to. Must be in the format 'organizations/{organization_id}'. | string | n/a | yes |
| enable_custom_mode_vpc_constraint | Enable the custom mode VPC custom constraint. | bool | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| custom_constraint_name | The name of the custom constraint for custom mode VPC. |
| policy_name | The name of the policy for custom mode VPC. |

## Validation

To validate that the custom constraint is working, try to create a VPC network in auto mode. The operation should fail with a `Constraint violated` error.

You can use the following `gcloud` command to try and create an auto-mode VPC network:

```bash
gcloud compute networks create my-auto-network --subnet-mode=auto
```
