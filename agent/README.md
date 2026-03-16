# GCP Hardening Agent

This directory contains the components of the GCP Hardening Agent, an agentic solution for automated hardening of GCP environments.

## state-exporter

The `state-exporter` directory contains a script to export GCP resource configurations from a specified project into a BigQuery table for analysis. This provides a snapshot of the current state of key assets.

### Overview

This module acts as a data-gathering prerequisite for the main GCP Hardening Agent. While its use is optional, running this exporter is highly recommended to provide the hardening agent with comprehensive data for a more thorough analysis.

The `export_cai_state.sh` script performs the following actions:
1.  Prompts the user for a target GCP Project ID.
2.  Enables the Cloud Asset API (`cloudasset.googleapis.com`) in the specified project.
3.  Creates a BigQuery dataset named `hardening_agent_cai_state` if it doesn't already exist.
4.  Exports specific asset types (`compute.googleapis.com/Instance`, `compute.googleapis.com/Firewall`, `iam.googleapis.com/ServiceAccount`) into a new, timestamped BigQuery table within that dataset.
5.  Polls the export operation and waits for it to complete, ensuring the data is fully populated before the script finishes.

### Prerequisites

Before running the script, ensure you have:
1.  The `gcloud` and `bq` command-line tools installed and authenticated.
2.  Sufficient IAM permissions in the target project, including:
    *   `serviceusage.services.enable`
    *   `bigquery.datasets.create`
    *   `bigquery.tables.create`
    *   `cloudasset.assets.export`

### Usage

The script is interactive. To run it:

```bash
bash state-exporter/export_cai_state.sh
```

You will be prompted to enter the GCP Project ID where the resources are located and where the export will be stored.

### Cleanup

A cleanup script is provided to remove the resources created by the exporter. This script will delete the entire `hardening_agent_cai_state` BigQuery dataset, including all tables within it.

To run the cleanup script:

```bash
bash state-exporter/cleanup.sh
```

You will be prompted to enter the same GCP Project ID to ensure the correct dataset is removed.
