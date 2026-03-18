# GCP Hardening Agent

This directory contains various components for the GCP Hardening Agent, such as exporters, extensions, and other related functionalities for automated hardening of GCP environments.

## state-exporter

The `state-exporter` sub-directory contains scripts to export GCP resource configurations. For detailed information on its functionality, prerequisites, and usage, please refer to its dedicated README: [`state-exporter/README.md`](state-exporter/README.md)

# Gemini Extension: Hardening Agent

The **Hardening Agent** is a specialized security assistant designed to triage GCP environments and generate hardening blueprints. It leverages the Model Context Protocol (MCP) to query BigQuery, which acts as the central hub for security telemetry, logs, and asset inventory.

## 🏗️ System Architecture

The agent integrates modules, discovery scripts, and human-in-the-loop (HITL) input to produce actionable security outcomes.

*   **Central Hub:** BigQuery (connected via MCP).
*   **Data Ingestion Sources:**
    *   **IAM:** Identity and Access Management monitoring.
    *   **Asset Inventory:** Real-time visibility of GCP resources.
    *   **Cloud Logging:** Audit and flow logs.
    *   **Cloud Firewall Rules:** Network security posture.
    *   **Security Command Center (SCC):** Threat detection and vulnerabilities.
*   **Infrastructure State:** Processes `.tfstate` from **Cloud Storage** to correlate live assets with Terraform-managed resources.

## ⚙️ Setup & Configuration

To use this extension in the **Gemini CLI**, you need to install it by running the following command:

# TODO
```bash
gemini extensions install https://github.com/GoogleCloudPlatform/gcp-hardening-toolkit
```

### 2. Verify Connection
The extension uses the Google-hosted BigQuery MCP server.

Ensure the BigQuery MCP server is enabled in your project:
```bash
gcloud beta services mcp enable bigquery.googleapis.com --project=PROJECT_ID
```

Also make sure you have active Google Cloud credentials:
```bash
gcloud auth application-default login
```

---

## 🛠️ BigQuery MCP Integration

The extension connects to the Google-hosted BigQuery MCP server.

- **MCP Server Name:** `bigquery`
- **Server URL:** `https://bigquery.googleapis.com/mcp`
- **Auth Provider:** `google_credentials`
- **OAuth Scopes:** `https://www.googleapis.com/auth/bigquery`

### Available Tools

The following tools are available via the `bigquery` MCP server:

| Tool Name | Description | Hardening Use Case |
| :--- | :--- | :--- |
| `list_datasets` | Lists datasets in a project. | Identifying security-related telemetry datasets. |
| `list_tables` | Lists tables in a dataset. | Locating specific log tables (e.g., Firewall or Audit). |
| `get_schema` | Retrieves table schemas. | Mapping SCC findings or Asset Inventory metadata. |
| `execute_sql` | Executes BigQuery SQL queries. | Identifying over-privileged accounts or open ports. |
| `list_jobs` | Lists recent BigQuery jobs. | Auditing agent activity and data access. |

### Limitations

- **Query Timeout:** The `execute_sql` tool limits query processing time to **3 minutes**. Queries exceeding this limit are automatically canceled.
- **External Tables:** Does not support querying Google Drive external tables.

## 🔄 Operational Workflow

1.  **Triage:** Uses `execute_sql` to pull data from **Asset Inventory** and **Cloud Firewall Rules**.
2.  **Discovery:** Correlates **SCC** findings with **Cloud Logging**.
3.  **State Reconciliation:** Reads `.tfstate` to align with Infrastructure-as-Code.
4.  **Blueprint Generation:** Outputs a finalized **Hardening Blueprint**.

## 💡 Sample Prompts

- "List the datasets in project `PROJECT_ID`."
- "Find the top firewall deny logs in dataset `DATASET_ID` for project `PROJECT_ID`."
- "Show the schema for the `assets` table in project `PROJECT_ID`."
- "Run a query to find all service accounts with the Owner role in project `PROJECT_ID`."

---
*For more information, see the [official BigQuery MCP documentation](https://docs.cloud.google.com/bigquery/docs/use-bigquery-mcp).*
