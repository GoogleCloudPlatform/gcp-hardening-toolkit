# GCP Hardening Toolkit

This repository contains a collection of curated Terraform modules designed to enhance the security posture of your Google Cloud Platform (GCP) environment. Each module is a reusable, documented, and tested component that applies a specific security best practice.

This repository is composed of the following hardening stages:

*   [gcp-foundation-org-iam](./gcp-foundation-org-iam): Manages Google Cloud Identity Groups and assigns IAM roles to them at the organization or folder level.
*   [gcp-foundation-org-policies](./gcp-foundation-org-policies): Manages GCP organization policies.
*   [gcp-constraint-workforce-pool](./gcp-constraint-workforce-pool): Applies an Organization Policy to restrict which IAM roles can be granted to Workforce Identity Pools.
*   [gcp-compliance-hipaa](./gcp-compliance-hipaa): Provides a starting point for HIPAA compliance by configuring audit logs, project creation enforcers, and security alerts.

## Usage

Each of the subdirectories in this repository is a self-contained Terraform module. To use a module, navigate to the subdirectory and follow the instructions in the `README.md` file.

## Contributing

Contributions are welcome! If you have a module idea, find a bug, or want to suggest an improvement, please open an issue or submit a pull request.
