# GCP Hardening Toolkit - State Exporter

This directory contains scripts to export the state of your GCP projects for security hardening analysis.

## Prerequisites

Ensure you have the `gcloud` CLI and `bq` command-line tools installed and configured.

## Scripts

- `export_cai_state.sh [PROJECT_ID]`: Initiates Cloud Asset Inventory (CAI) resources export to BigQuery. After execution, it will provide a `gcloud` command to check the operation's status. The BigQuery table will be populated upon completion.
- `export_scc_state.sh [PROJECT_ID] [ORG_ID]`: Initiates Security Command Center (SCC) findings export to BigQuery. After execution, it will provide a `gcloud` command to check the operation's status. Once the export operation is complete, you will need to manually run a `bq query` command (provided by the script) to create the `actionable_findings` view.
- `cleanup.sh [PROJECT_ID]`: Deletes the BigQuery dataset created by the CAI export script.

## Usage

To run the scripts, navigate to this directory in your terminal and execute the desired script with the required parameters.

### `export_cai_state.sh`

Exports Cloud Asset Inventory resources.

```bash
./export_cai_state.sh YOUR_GCP_PROJECT_ID
```

Replace `YOUR_GCP_PROJECT_ID` with the ID of your GCP project.

### `export_scc_state.sh`

Exports Security Command Center findings.

```bash
./export_scc_state.sh YOUR_GCP_PROJECT_ID YOUR_GCP_ORGANIZATION_ID
```

Replace `YOUR_GCP_PROJECT_ID` with your GCP project ID and `YOUR_GCP_ORGANIZATION_ID` with your GCP organization ID.

### `cleanup.sh`

Deletes the BigQuery dataset and its contents created by the `export_cai_state.sh` script.

```bash
./cleanup.sh YOUR_GCP_PROJECT_ID
```

Replace `YOUR_GCP_PROJECT_ID` with the ID of the GCP project where the dataset was created.

## IAM Permissions for SCC Export to BigQuery

When exporting SCC findings to BigQuery, the Security Command Center service account needs appropriate permissions to write to the BigQuery dataset. The service account typically follows the format `service-org-YOUR_ORG_ID@security-center-api.iam.gserviceaccount.com`.

You need to grant the `BigQuery Data Editor` role (`roles/bigquery.dataEditor`) to this service account on your project.

**Example Command:**

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:service-org-YOUR_ORG_ID@security-center-api.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataEditor"
```

Replace `YOUR_PROJECT_ID` with your actual project ID and `YOUR_ORG_ID` with your organization ID.
