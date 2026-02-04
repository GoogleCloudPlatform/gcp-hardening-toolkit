# AlloyDB Logging Constraints

This module creates custom organization policy constraints to enforce logging-related database flags for AlloyDB instances.

## Constraints

| Constraint Name | Database Flag | Required Value |
|---|---|---|
| `custom.alloydbLogErrorVerbosity` | `log_error_verbosity` | `default` |
| `custom.alloydbLogMinErrorStatement` | `log_min_error_statement` | `error` |
| `custom.alloydbLogMinMessages` | `log_min_messages` | `warning` |

## Usage

```hcl
module "alloydb_logging" {
  source = "./modules/gcp-custom-constraints/alloydb/logging-constraints"
  parent = "organizations/123456789012"
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| `parent` | The parent resource (org, folder, project) | `string` | yes |

## Outputs

| Name | Description |
|------|-------------|
| `constraint_names` | Map of created constraint names |
