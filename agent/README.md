# GCP Hardening Agent

The GCP Hardening Agent is a specialized security assistant designed to triage Google Cloud environments and generate hardening blueprints. It functions as an interactive CLI agent that automates the audit of existing infrastructure to identify vulnerabilities and deploy incremental compliance guardrails.

## Basic Install and Setup

### Prerequisites

Ensure the following tools are installed and configured:

- gcloud CLI
- bq command-line tool
- Terraform (>= 1.3)

### Initial Setup

To populate the agent's central hub (BigQuery) with your environment's state, use the scripts provided in the state-exporter directory.

#### Project-level Export

1. Navigate to the state-exporter directory:
   ```bash
   cd agent/state-exporter
   ```

2. Export Cloud Asset Inventory (CAI) resources for a specific project:
   ```bash
   ./export_cai_state.sh YOUR_GCP_PROJECT_ID
   ```
   Replace `YOUR_GCP_PROJECT_ID` with your project's ID.

#### Organization-level Export

1. Export CAI resources for an entire organization:
   ```bash
   ./export_cai_org_state.sh YOUR_ORG_ID YOUR_BILLING_PROJECT_ID
   ```
   Replace `YOUR_ORG_ID` and `YOUR_BILLING_PROJECT_ID` with the appropriate IDs.

### Verification

After triggering an export, verify the operation's status using the gcloud command provided in the script's output (e.g., `gcloud asset operations describe ...`). Once complete, the BigQuery tables will be populated and ready for the agent to analyze.

## System Architecture

The agent operates within the GCP Hardening Toolkit environment, integrating modules, discovery scripts, and human-in-the-loop input to produce actionable security outcomes.

- Central Hub: BigQuery (connected via Model Context Protocol - MCP).
- Infrastructure State: Processes .tfstate from Cloud Storage to correlate live assets with Terraform-managed resources.

### Data Ingestion Sources

The agent leverages telemetry and configuration data from several sources stored in BigQuery:

- IAM: Identity and Access Management monitoring.
- Asset Inventory: Real-time visibility of GCP resources.
- Cloud Logging: Audit and flow logs.
- Cloud Firewall Rules: Network security posture.
- Security Command Center (SCC): Threat detection and vulnerabilities.

## Core Capabilities

The agent utilizes BigQuery MCP tools to analyze the environment:

- list_datasets: Identify security-related telemetry datasets.
- list_tables: Locate specific log tables (e.g., Firewall or Audit logs).
- get_schema: Map SCC findings or Asset Inventory metadata.
- query: Execute BigQuery SQL to identify over-privileged accounts, open ports, and other misconfigurations.
- list_jobs: Audit agent activity and data access.

## Operational Workflow

1. Triage: The agent pulls data from Asset Inventory and Cloud Firewall Rules stored in BigQuery.
2. Discovery: Correlates SCC findings with Cloud Logging to identify active misconfigurations.
3. State Reconciliation: Reads .tfstate from Cloud Storage to ensure hardening measures align with existing Infrastructure-as-Code.
4. Blueprint Generation: Outputs a finalized Hardening Blueprint based on analysis and user input.

## Sub-components

### State Exporter

The state-exporter directory contains scripts for exporting GCP resource configurations for analysis. For more details on its functionality and usage, see agent/state-exporter/README.md.
