# GCP Hardening Toolkit - State Exporter

This directory contains scripts to export the state of your GCP projects for security hardening analysis.

## Prerequisites

Ensure you have the `gcloud` CLI and `bq` command-line tools installed and configured.

## Scripts

- `export_cai_state.sh [PROJECT_ID]`: Initiates Cloud Asset Inventory (CAI) resources export for a specific project to BigQuery. After execution, it will provide a `gcloud` command to check the operation's status.

- `export_cai_org_state.sh [ORG_ID] [BILLING_PROJECT_ID] [DATASET_NAME]`: Initiates Organization-wide CAI export for an entire organization using a specific billing project.

- `export_scc_state.sh [PROJECT_ID] [BUCKET_NAME]`: Exports Security Command Center (SCC) findings for a specific project to a Cloud Storage bucket (created automatically if it doesn't exist).

- `export_scc_org_state.sh [ORG_ID] [BILLING_PROJECT_ID] [BUCKET_NAME]`: Exports Organization-wide SCC findings to a Cloud Storage bucket using a specific billing project (created automatically if it doesn't exist).

- `cleanup.sh [PROJECT_ID]`: Deletes the BigQuery dataset created by the project-level CAI export script.

## Usage

To run the scripts, navigate to this directory in your terminal and execute the desired script with the required parameters.

### `export_cai_state.sh`

Exports Cloud Asset Inventory resources for a project.

```bash
./export_cai_state.sh YOUR_GCP_PROJECT_ID
```

### `export_cai_org_state.sh`

Exports Cloud Asset Inventory resources for an entire organization.

```bash
./export_cai_org_state.sh YOUR_ORG_ID YOUR_BILLING_PROJECT_ID
```

### `export_scc_state.sh`

Exports Security Command Center findings for a project to Cloud Storage.

```bash
./export_scc_state.sh YOUR_GCP_PROJECT_ID [OPTIONAL_GCS_BUCKET_NAME]
```

### `export_scc_org_state.sh`

Exports Security Command Center findings for an entire organization to Cloud Storage.

```bash
./export_scc_org_state.sh YOUR_ORG_ID YOUR_BILLING_PROJECT_ID [OPTIONAL_GCS_BUCKET_NAME]
```

### `cleanup.sh`

Deletes the BigQuery dataset and its contents created by the `export_cai_state.sh` script.

```bash
./cleanup.sh YOUR_GCP_PROJECT_ID
```
