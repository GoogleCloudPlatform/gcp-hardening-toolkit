# GCP Hardening Agent

The GCP Hardening Agent is a professional security engineering assistant designed to triage Google Cloud environments and generate actionable hardening blueprints. It operates as a specialized extension for the **Gemini CLI**, enabling an interactive and automated approach to managing security debt in complex, brownfield environments.

## Basic Install and Setup

### Prerequisites

Ensure the following tools are installed and configured:

- **Gemini CLI**: The agent functions as a native extension of the Gemini CLI environment.
- **gcloud CLI**: Required for authentication and resource management.
- **bq command-line tool**: Necessary for querying security telemetry in BigQuery.
- **Terraform (>= 1.3)**: For deploying generated hardening blueprints.

### Initial Setup (Context Enrichment)

To enable the agent to analyze your environment effectively, you must first populate its central hub (BigQuery) with your environment's state. The scripts in the `state-exporter` directory are **essential prerequisites** for this context enrichment process.

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

## Role & Expertise

The Hardening Agent acts as a professional security peer, providing:

- **Posture Interpretation**: Analyzing Cloud Asset Inventory (CAI) data and security telemetry stored in BigQuery to identify vulnerabilities.
- **Consultative Hardening**: Asking the user about specific hardening requirements and constraints.
- **Blueprint Generation**: Designing and implementing new, custom Terraform blueprints (e.g., `ght-agent-generated-blueprint`) by leveraging the toolkit's stateless modules.

## System Architecture

The agent operates as a Gemini CLI extension, integrating modules, discovery scripts, and user input to produce actionable security outcomes.

- **Central Hub**: BigQuery (connected via Model Context Protocol - MCP) containing Cloud Asset Inventory data.
- **Codebase Access**: The agent is grounded in the `gcp-hardening-toolkit` repository, allowing it to read and reuse existing `modules/` and `blueprints/`.

## Core Capabilities

The agent utilizes BigQuery tools to analyze the environment:

- **Data Fetching**: Querying CAI resources, IAM bindings, and firewall rules.
- **Misconfiguration Identification**: Identifying over-privileged accounts, open network ports, and missing security controls.
- **Incremental Hardening**: Recommending and generating blueprints for non-disruptive remediation.

## Operational Workflow

1. **Triage & Enrichment**: The agent verifies the presence of CAI data in BigQuery. If missing, it recommends running the `state-exporter` scripts.
2. **Requirement Gathering**: The agent consults with the user to define hardening goals and constraints.
3. **Blueprint Generation**: Based on the gathered requirements, the agent generates a new, ready-to-deploy blueprint using appropriate toolkit modules.

## Sub-components

### State Exporter

The `state-exporter` directory contains the critical scripts needed to export your GCP environment's live state for analysis. For more details, see [agent/state-exporter/README.md](state-exporter/README.md).
