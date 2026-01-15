# Cloud SQL Disallow External Scripts Custom Constraint

This module creates a custom organization policy constraint that ensures the 'external scripts enabled' flag is set to 'off' for all Cloud SQL for SQL Server instances.

**Note:** This constraint only applies to Cloud SQL for SQL Server instances. It does not affect other database types like MySQL or PostgreSQL.

## Usage

```terraform
module "disallow_external_scripts_constraint" {
  source = "github.com/your-repo/gem-gcp-constraints/modules/sql/disallow-external-scripts-constraint"
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

To validate that the custom constraint is working, try to create a Cloud SQL for SQL Server instance with the 'external scripts enabled' flag set to 'on'. The operation should fail with a `Constraint violated` error.

You can use the following `gcloud` command to try and create an instance with the flag set to 'on':

```bash
gcloud sql instances create my-test-sql-server \
  --database-version=SQLSERVER_2019_STANDARD \
  --region=us-central1 \
  --root-password=your-password \
  --database-flags=external_scripts_enabled=on
```

