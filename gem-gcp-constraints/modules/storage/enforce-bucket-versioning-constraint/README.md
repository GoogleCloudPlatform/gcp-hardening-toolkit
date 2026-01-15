# Enforce Bucket Versioning Constraint

This Terraform module creates a custom organization policy constraint to enforce that all Cloud Storage buckets have object versioning enabled.

## Usage

```hcl
module "enforce_bucket_versioning" {
  source = "./modules/storage/enforce-bucket-versioning-constraint"

  parent = "organizations/123456789012"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| parent | The parent resource to attach the policy to. Must be in the format 'organizations/{organization\_id}'. | string | n/a | yes |
