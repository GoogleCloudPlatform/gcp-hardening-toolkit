# GEMINI.md: Hardening Agent Extension

The **Hardening Agent** is a specialized security assistant designed to triage GCP environments and generate hardening blueprints. It leverages the Model Context Protocol (MCP) to query BigQuery, which acts as the central hub for security telemetry, logs, and asset inventory.

---

## 🏗️ System Architecture

The agent operates within the `gcp-hardening-toolkit` (Cloud Shell), integrating modules, discovery scripts, and human-in-the-loop (HITL) input to produce actionable security outcomes.

*   **Central Hub:** BigQuery (connected via MCP).
*   **Data Ingestion Sources:**
    *   **IAM:** Identity and Access Management monitoring.
    *   **Asset Inventory:** Real-time visibility of GCP resources.
    *   **Cloud Logging:** Audit and flow logs.
    *   **Cloud Firewall Rules:** Network security posture.
    *   **Security Command Center (SCC):** Threat detection and vulnerabilities.
*   **Infrastructure State:** Processes `.tfstate` from **Cloud Storage** to correlate live assets with Terraform-managed resources.

---

## 🛠️ MCP Tool Capabilities (BigQuery)

The agent utilizes the following tools via the `bigquery` MCP server to analyze the environment:

| Tool Name | Functional Description | Hardening Use Case |
| :--- | :--- | :--- |
| `list_datasets` | Lists datasets in a project. | Identifying security-related telemetry datasets. |
| `list_tables` | Lists tables in a dataset. | Locating specific log tables (e.g., Firewall or Audit). |
| `get_schema` | Retrieves table schemas. | Mapping SCC findings or Asset Inventory metadata. |
| `query` | Executes BigQuery SQL. | Identifying over-privileged accounts or open ports. |
| `list_jobs` | Lists recent BigQuery jobs. | Auditing agent activity and data access. |

---

## 🔄 Operational Workflow

1.  **Triage:** The agent uses `query` to pull data from **Asset Inventory** and **Cloud Firewall Rules** stored in BigQuery.
2.  **Discovery:** Correlates **SCC** findings with **Cloud Logging** to identify active misconfigurations.
3.  **State Reconciliation:** Reads `.tfstate` from **Cloud Storage** to ensure hardening measures align with existing Infrastructure-as-Code.
4.  **Blueprint Generation:** Outputs a finalized **Hardening Blueprint** based on analysis and user input.