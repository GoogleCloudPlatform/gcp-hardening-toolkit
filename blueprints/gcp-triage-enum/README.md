# GCP Triage Enum

This blueprint provides a simple Bash script designed to perform a rapid security triage and enumeration of a Google Cloud Platform (GCP) project.

## Overview

The `enum-project.sh` script provides a comprehensive security overview of a GCP project. It starts with a clear welcome message, details its scope, and concludes with a summary.

It assesses the following areas:
- **Project Metadata**: Gathers essential details like creation time, lifecycle state, parent information, and project number.
- **IAM Assessment**:
  - Identifies user accounts from outside a defined list of trusted domains.
  - Lists highly privileged accounts with "Owner" or "Editor" roles.
- **Network Assessment**:
  - Checks for the existence of the default VPC.
  - Details the total number of VPC networks.
  - Lists any firewall rules allowing inbound traffic from the public internet (`0.0.0.0/0`).
- **Cloud DNS Assessment**:
  - Checks if Private DNS is enabled on all VPC networks.
  - Verifies if DNSSEC is enabled for private managed zones.
- **Public Resource Exposure**:
  - Scans for GCS Buckets and BigQuery Datasets shared with `allUsers` or `allAuthenticatedUsers`.
- **Infrastructure Exposure**:
  - Lists Compute instances with External IPs.
  - Identifies Cloud SQL instances with Public IP enabled.
- **Service Account Hardening**:
  - Checks for Compute instances using the default Compute service account.
  - Identifies Service Account keys older than 90 days.
- **Serverless & Artifact Exposure**:
  - Scans for Cloud Run and Cloud Functions with unauthenticated access enabled (`allUsers`).
  - Identifies public Artifact Registry repositories.
- **Network Visibility (Flow Logs)**:
  - Lists VPC subnets where Flow Logs are disabled.
- **VM-Level Hardening**:
  - Verifies if project-wide SSH keys are blocked.
  - Lists instances with Serial Port access enabled.

## Prerequisites

- [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install) installed and authenticated.
- [`jq`](https://jqlang.github.io/jq/) installed for parsing JSON output.
- Appropriate IAM permissions on the target GCP project to view project metadata, IAM policies, and compute networks/firewalls.

## Usage

1.  Open `enum-project.sh` and edit the `TRUSTED_DOMAINS` array to include your organization's allowed domains:
    ```bash
    TRUSTED_DOMAINS=(
      "yourdomain.com"
    )
    ```
2.  Run the script by passing the target GCP project ID as an argument:
    ```bash
    ./enum-project.sh <project-id>
    ```

## Output

The script's output is designed for clarity:
- A **welcome message** at the start explains the script's scope.
- **Section headers** organize the findings for easy review.
- A **footer message** confirms the completion of the scan.
