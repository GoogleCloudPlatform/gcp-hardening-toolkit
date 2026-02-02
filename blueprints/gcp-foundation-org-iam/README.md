# gcp-foundation-org-iam

This Terraform module creates Google Cloud Identity Groups and assigns IAM roles to them at the organization or folder level.

## Usage

```hcl
module "google_groups" {
  source = "./modules/org-iam"

  groups      = var.groups
  customer_id = var.customer_id
  domain      = var.domain
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `groups` | A list of groups to create. If `folder_id` is provided, the roles will be applied at the folder level, otherwise they will be applied at the organization level. | `list(object({ display_name = string, description = string, folder_id = optional(string), roles = list(string) }))` | `[]` | yes |
| `customer_id` | The customer ID for the organization. | `string` | `""` | yes |
| `domain` | The domain of the organization. | `string` | `""` | yes |
| `allow_multi_point_grants` | Allow the same group to be defined multiple times for different folder permissions. If `false`, the plan will fail if duplicate group names are found. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `group_ids` | The IDs of the created groups. |

## Example

### `main.tf`

```hcl
module "google_groups" {
  source = "./modules/org-iam"

  groups      = var.groups
  customer_id = var.customer_id
  domain      = var.domain
}
```

### `terraform.tfvars`

```hcl
groups = [
  {
    display_name = "gcp-billing-admins"
    description  = "GCP Billing Administrators"
    roles        = ["roles/billing.admin"]
  },
  {
    display_name = "gcp-organization-admins"
    description  = "GCP Organization Administrators"
    roles = [
      "roles/resourcemanager.organizationAdmin",
      "roles/resourcemanager.organizationViewer"
    ]
  },
  {
    display_name = "gcp-security-admins"
    description  = "GCP Security Administrators"
    folder_id    = "folders/123456789012"
    roles        = ["roles/iam.securityAdmin"]
  }
]

customer_id = "C01234567"
domain      = "example.com"
```

## Important

### Quota Project

This module uses the Cloud Identity API. To use this API, you need to have a Google Cloud project with the Cloud Identity API enabled. This project is called the "quota project".

You can set the quota project for your Application Default Credentials in a few ways:

1.  **Using `gcloud` (recommended):**

    ```bash
    gcloud auth application-default set-quota-project YOUR_PROJECT_ID
    ```

    Replace `YOUR_PROJECT_ID` with the ID of your quota project.

2.  **Using environment variables:**

    You can set the `GOOGLE_CLOUD_PROJECT` or `GOOGLE_PROJECT` environment variable to your quota project ID. `GOOGLE_CLOUD_PROJECT` takes precedence over `GOOGLE_PROJECT`.

    ```bash
    export GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID"
    ```

    or

    ```bash
    export GOOGLE_CLOUD_QUOTA_PROJECT="YOUR_PROJECT_ID"
    ```

### Cloud Identity API

You also need to make sure that the Cloud Identity API is enabled in your quota project. You can enable it by running the following command:

```bash
gcloud services enable cloudidentity.googleapis.com --project YOUR_PROJECT_ID
```

Replace `YOUR_PROJECT_ID` with the ID of your quota project.

### Permissions for Service Accounts

When using a Google Cloud Service Account to run this Terraform module, it needs specific permissions within your Google Workspace environment to create groups. **These permissions must be granted by a Google Workspace super administrator.**

The following steps describe the recommended, most secure method for granting these permissions by creating a custom admin role.

1.  **Sign in** to the [Google Admin console](https://admin.google.com).
2.  **Navigate to Admin Roles:** Go to `Account` > `Admin roles`.
3.  **Create a New Role:**
    *   Click `Create new role`.
    *   Give it a name like "Terraform Group Creator".
    *   For the description, you can add "Allows a service account to create Google Groups via the API".
4.  **Assign Privileges:**
    *   Click `Continue`.
    *   Find the `Groups` privilege.
    *   Check the box for `Create`.
    *   Click `Continue` and then `Create Role`.
5.  **Assign the Role to the Service Account:**
    *   Go back to the list of `Admin roles`.
    *   Click on the new role you just created ("Terraform Group Creator").
    *   Click `Assign service accounts`.
    *   Enter the email address of the service account being used by Terraform.
    *   Click `Add` and then `Assign Role`.
