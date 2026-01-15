# Disallow External Scripts SQL Server Constraint Test

This folder contains a Terraform test for a Google Cloud SQL Server constraint that disallows the use of external scripts.

## Purpose

The Terraform code in this test is designed to verify the behavior of a constraint that prevents SQL Server instances from having the `external scripts enabled` flag set to `on`. This is a security measure to prevent the execution of potentially malicious scripts.

## How it Works

The `main.tf` file defines two SQL Server instances:

1.  **Compliant Instance (`compliant_sql_server`):** This instance is configured with the `external scripts enabled` flag set to `off`. When you apply this configuration with the constraint in place, this resource should be created successfully.

2.  **Violating Instance (`violating_sql_server`):** This instance is configured with the `external scripts enabled` flag set to `on`. When you apply this configuration with the constraint in place, the creation of this resource should be **blocked** by the policy. You will see an error, indicating a constraint violation.

## Usage

To use this test:

1.  Make sure you have a Google Cloud project and have authenticated your Terraform environment.
2.  Apply the organizational policy or constraint that disallows external scripts for SQL Server instances.
3.  Navigate to this directory (`gem-gcp-constraints/tests/sql/disallow-external-scripts-constraint`).
4.  Run `terraform init`.
5.  Run `terraform apply`.

You should see that `compliant_sql_server` is created, but the creation of `violating_sql_server` fails with a constraint violation error. This confirms the policy is working as expected.
