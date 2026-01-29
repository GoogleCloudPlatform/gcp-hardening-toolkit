# GCP Hardening Toolkit

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This repository contains a collection of curated Terraform modules designed to enhance the security posture of your Google Cloud Platform (GCP) environment. Each module is a reusable, documented, and tested component that applies a specific security best practice.

## Core Principles

* **Modular:** Each hardening step is a self-contained module that can be used independently.
* **Customizable:** Modules expose variables to allow for customization without needing to alter the source code.
* **Documented:** Every module includes a detailed `README.md` explaining its purpose, variables, and outputs.

## Prerequisites

Before you begin, ensure you have the following:

1.  **Terraform v1.x** or later installed.
2.  **Google Cloud SDK (`gcloud`)** installed and authenticated.
    ```bash
    gcloud auth application-default login
    ```
3.  **Required Permissions** in your GCP organization or project. Many modules require roles like `roles/orgpolicy.policyAdmin` or `roles/iam.securityAdmin` to apply changes.

## Available Modules

This toolkit includes the following modules located in the `./modules` directory:

| Module                                                                          | Description                                                                                                        |
| :------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------- |
| [`iam-workforce-pool-constraint`](./modules/iam-workforce-pool-constraint)        | Applies an Organization Policy to restrict which IAM roles can be granted to Workforce Identity Pools.           |


## Quick Start: Using a Module

To use a module, you create a standard Terraform configuration (`.tf` file) and call the module from within it.

1.  **Create a `main.tf` file** in your project:

    ```terraform
    # main.tf

    terraform {
      required_providers {
        google = {
          source  = "hashicorp/google"
          version = ">= 4.50.0"
        }
      }
    }

    # Configure the Google Cloud provider
    provider "google" {
      project = var.gcp_project_id
    }

    # Define variables needed for the module
    variable "gcp_project_id" {
      description = "The GCP project ID to configure the provider."
      type        = string
    }

    variable "organization_id" {
      description = "The GCP organization ID where the policy will be applied."
      type        = string
    }

    # Call the module from the toolkit
    module "restrict_workforce_roles" {
      # This source path points to the module's folder within this repository
      source = "./modules/iam-workforce-pool-constraint"

      # Provide the required variables for the module
      organization_id = var.organization_id

      # (Optional) Override default variables
      allowed_roles_prefixes = [
        "roles/iap.webServiceUser",
        "roles/cloudsql.client",
        "roles/artifactregistry.reader"
      ]
    }
    ```

2.  **Create a `terraform.tfvars` file** to supply your values:

    ```hcl
    # terraform.tfvars

    gcp_project_id  = "your-gcp-project-123"
    organization_id = "123456789012"
    ```

3.  **Initialize and apply Terraform**:
    ```bash
    terraform init
    terraform apply
    ```

## Contributing

Contributions are welcome! If you have a module idea, find a bug, or want to suggest an improvement, please open an issue or submit a pull request.
