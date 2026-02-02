# GCP Foundation Security

This repository contains Terraform configurations and scripts to set up a basic security foundation in a Google Cloud Platform (GCP) organization. It activates Security Command Center (SCC), enables all the necessary services and modules, and provides a starting point for deploying other security configurations like project creation enforcer and notification channels.

## How it works

This repository has three main components:

1.  **Shell Scripts:** The `enable_scc_services.sh` and `enable_sha_modules.sh` scripts enable the Security Command Center services and Security Health Analytics modules in your organization.

2.  **Terraform Configuration:** The Terraform configuration in this repository is responsible for the following:
    *   **Audit Logs:** Enables `ADMIN_READ`, `DATA_READ`, and `DATA_WRITE` audit logs for all services at the organization level.
    *   **Project Creation Enforcer:** This module automatically enables the Cloud Asset API on all newly created projects within the organization. It does this by deploying a Cloud Function that is triggered by a Pub/Sub message from a log sink. The log sink is configured to capture project creation events. This ensures that all new projects are immediately brought into compliance with the organization's security policies.
    *   **Security Alerts:** Creates a notification channel and several logging metrics and corresponding alert policies for:
        *   Cloud Storage IAM permission changes
        *   DDoS attacks

## Disclaimer

This repository provides a proof-of-concept (POC) implementation for a basic security foundation on Google Cloud Platform. It is not intended to be a complete, production-ready compliance solution. The configurations and scripts are examples designed to demonstrate how to enforce compliance on projects and create common compliance-related alerts. You should review and adapt the code to meet the specific security and compliance requirements of your organization.

## How to use this repository

Here is the recommended workflow to set up your GCP security foundation:

### Prerequisites

*   **Google Cloud SDK:** You need to have the `gcloud` command-line tool installed and configured to authenticate to your GCP account.
*   **Terraform:** You need to have Terraform installed on your local machine.
*   **Permissions:** The user or service account running the scripts and Terraform configuration needs the following roles:
    **Organization Level:**
    *   `roles/resourcemanager.organizationAdmin`
    *   `roles/securitycenter.settingsAdmin`
    *   `roles/logging.configWriter`
    *   `roles/serviceusage.serviceUsageAdmin`

    **Project Level (for both the quota project and the log project):**
    *   `roles/owner` or the following roles:
        *   `roles/resourcemanager.projectIamAdmin`
        *   `roles/iam.serviceAccountAdmin`
        *   `roles/storage.admin`
        *   `roles/pubsub.admin`
        *   `roles/cloudfunctions.admin`
        *   `roles/run.admin`
        *   `roles/monitoring.notificationChannelEditor`
        *   `roles/logging.configWriter`
        *   `roles/monitoring.alertPolicyEditor`

### Step 1: Configure your environment

1.  **Enable APIs:** The following APIs must be enabled in the quota project for the Terraform configuration to apply successfully:

    *   `cloudbuild.googleapis.com`
    *   `serviceusage.googleapis.com`
    *   `cloudfunctions.googleapis.com`
    *   `artifactregistry.googleapis.com`
    *   `storage.googleapis.com`
    *   `run.googleapis.com`
    *   `eventarc.googleapis.com`

    You can enable them by running the following commands:

    ```bash
    gcloud services enable cloudbuild.googleapis.com --project <YOUR_QUOTA_PROJECT>
    gcloud services enable serviceusage.googleapis.com --project <YOUR_QUOTA_PROJECT>
    gcloud services enable cloudfunctions.googleapis.com --project <YOUR_QUOTA_PROJECT>
    gcloud services enable artifactregistry.googleapis.com --project <YOUR_QUOTA_PROJECT>
    gcloud services enable storage.googleapis.com --project <YOUR_QUOTA_PROJECT>
    gcloud services enable run.googleapis.com --project <YOUR_QUOTA_PROJECT>
    gcloud services enable eventarc.googleapis.com --project <YOUR_QUOTA_PROJECT>
    ```

2.  **Configure Shell Scripts:** Before running the `enable_scc_services.sh` and `enable_sha_modules.sh` scripts, you must update the following variables in both files:

    *   `ORGANIZATION_ID`: Your GCP organization ID.
    *   `QUOTA_PROJECT`: The project to use for quota and billing.

3.  **Configure Terraform Variables:** Create a `terraform.tfvars` file in the root of the repository and add the following variables:

    ```terraform
    organization_id                 = "<YOUR_ORGANIZATION_ID>"
    quota_project                   = "<YOUR_QUOTA_PROJECT>"
    log_project_id                  = "<YOUR_LOG_PROJECT_ID>"
    notification_email              = "<YOUR_SECURITY_ADMINISTRATORS_EMAIL>"
    ```

### Step 2: Run the Shell Scripts

Run the scripts from your terminal:

```bash
./enable_scc_services.sh
./enable_sha_modules.sh
```

### Step 3: Apply the Terraform Configuration

Initialize and apply the Terraform configuration:

```bash
terraform init
terraform apply
```
