# GCP Triage Enum

This blueprint provides a simple Bash script designed to perform a rapid security triage and enumeration of a Google Cloud Platform (GCP) project.

## Overview

The `enum-project.sh` script gathers essential project metadata, assesses IAM policies for untrusted users, and performs a basic network assessment. 

It checks for:
- **Project Metadata**: Creation time, lifecycle state, parent details, and project number.
- **IAM Assessment**: Identifies users external to a defined list of trusted domains.
- **Network Assessment**: Checks for the existence of the default VPC, details the total number of VPC networks, and highlights any firewall rules allowing inbound traffic from the internet (`0.0.0.0/0`).

## Prerequisites

- [Google Cloud CLI (`gcloud`)](https://cloud.google.com/sdk/docs/install) installed and authenticated.
- [`jq`](https://jqlang.github.io/jq/) installed for parsing JSON output.
- Appropriate IAM permissions on the target GCP project to view project metadata, IAM policies, and compute networks/firewalls.

## Usage

1. Open `enum-project.sh` and edit the `TRUSTED_DOMAINS` array at the top of the script to include your organization's allowed domains:
   ```bash
   TRUSTED_DOMAINS=(
     "yourdomain.com"
   )
   ```
2. Run the script by passing the target GCP project ID as an argument:
   ```bash
   ./enum-project.sh <project-id>
   ```
