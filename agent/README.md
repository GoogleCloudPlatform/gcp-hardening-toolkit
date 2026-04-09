# GCP Hardening Agent

The GCP Hardening Agent is a professional security engineering assistant designed to triage Google Cloud environments and generate actionable hardening blueprints. It operates as a specialized extension for the **Gemini CLI**, enabling an interactive and automated approach to managing security debt in complex, brownfield environments.

## Installation and Setup

Follow these steps to bootstrap and initialize the interactive assistant:

### Installation

To install the Hardening Agent as a Gemini CLI extension, run:

```bash
gemini extensions install https://github.com/GoogleCloudPlatform/gcp-hardening-toolkit
```

### Prerequisites

Ensure the following tools are installed and configured:

| Name | Description | Recommended Minimal Version |
| :--- | :--- | :--- |
| Gemini CLI | The agent functions as a native extension of the Gemini CLI environment. | >= v0.32.0  |
| gcloud CLI | Required for authentication and resource management. | >= 559.0.0 |
| bq | Necessary for querying security telemetry in BigQuery. | >= 2.0.98 |
| Terraform | For deploying generated hardening blueprints. | >= 1.3 |

Follow these steps to bootstrap and initialize the interactive assistant:

1. **Export Telemetry Context (Must be run BEFORE starting the agent):** Navigate to `agent/state-exporter` and run the appropriate script to dump your environment's context.

   > [!IMPORTANT]
   > These export scripts **must be executed before** running the agent.
   > Furthermore, they must be executed by a **user account** (or a separate highly privileged service account) with permissions to export assets from Cloud Asset Inventory to BigQuery and Cloud Storage. Do not use the restricted service account intended for the agent execution here, as it lacks these permissions.

   **Option A: Project-Level Asset Export (Default)**
   ```bash
   cd agent/state-exporter
   ./export_cai_state.sh YOUR_PROJECT_ID
   ```

   **Option B: Organization-Level Asset Export**
   ```bash
   cd agent/state-exporter
   ./export_cai_org_state.sh YOUR_ORG_ID YOUR_BILLING_PROJECT_ID
   ```

   **Option C: Project-Level Security Command Center (SCC) Export**
   ```bash
   cd agent/state-exporter
   ./export_scc_state.sh YOUR_GCP_PROJECT_ID [OPTIONAL_GCS_BUCKET_NAME]
   ```

   **Option D: Organization-Level Security Command Center (SCC) Export**
   ```bash
   cd agent/state-exporter
   ./export_scc_org_state.sh YOUR_ORG_ID YOUR_BILLING_PROJECT_ID [OPTIONAL_GCS_BUCKET_NAME]
   ```

2. **Authenticate for Agent Execution:** You must authenticate with Google Cloud before running the agent.

   **Option A: Interactive User Login**
   ```bash
   gcloud auth application-default login
   ```

   **Option B: Service Account JSON Key**
   To authenticate using a Service Account JSON key:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/service-account-key.json"
   ```

   > [!NOTE]
   > When authenticating using a Service Account, the **Gemini for Google Cloud API** (`cloudaicompanion.googleapis.com`) must be enabled on your target project before running the `gemini` CLI. You can enable it via the Google Cloud Console or by running: `gcloud services enable cloudaicompanion.googleapis.com --project=YOUR_PROJECT_ID`


3. **Start the Interface:** The `gemini` CLI must be executed from the **repository root** so it can locate the `gemini-extension.json` configuration file.
   ```bash
   #Set your Google Cloud Project
   export GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID"
   gemini extensions link . #This command will link the gemini-extension.json to your Gemini environment
   gemini
   ```

### Example Prompts

Once the agent is running, you can interact with it to analyze your environment and generate blueprints. Here are some examples of requests you can make:

*   **Postural Analysis:** `"Can you analyze my exported asset inventory in BigQuery and identify any public IP addresses assigned to Compute Engine instances?"`
*   **IAM Audit:** `"List all service accounts that have primitive owner or editor roles assigned in the project."`
*   **Blueprint Generation:** `"Help me generate a Terraform blueprint to block service account creation using organization policies, referring to the stateless modules available in the repo."`

---

This document also covers the security model, architecture, and advanced configuration of the agent in the sections below.

## Security and Permissions (Least Privilege)

The `gemini-cli` uses [**application-default credentials (ADC)**](https://docs.cloud.google.com/docs/authentication/provide-credentials-adc) to authenticate to GCP for data read operations. These read operations are crucial for the hardening agent context. To ensure security, we must guarantee the agent only has reader permission and cannot perform any changes in the environment.

### ⚠️ Warning

> [!WARNING]
> DO NOT use administrator accounts to log into Google Cloud for the hardening agent.
> DO NOT enable [auto decision-making](#disabling-auto-decision-making) in the hardening agent.
>
> **Recommendation:** We recommend running the hardening agent using a Service Account as stated in [Option B](../README.md#option-b-service-account-json-key) of the root `README.md`. To follow the principle of least privilege, create the custom role for the viewer found in the `custom-role-creation` directory and assign it to the Service Account.

### Disabling Auto Decision-Making

The GCP Hardening Agent is designed for interactive use. It does not possess configuration flags for automated execution. To adhere to this guideline:
- **Interactive Session**: Always run the agent in an interactive terminal.
- **Manual Blueprint Review**: Manually inspect any generated Terraform blueprints before deployment.
- **No Unattended CI/CD**: Do not integrate the agent into fully automated pipelines without a human-in-the-loop approval stage.

### Service Account Creation

> [!NOTE]
> Creating a dedicated Service Account is only necessary if you plan to authenticate the agent using **Option B** (Service Account JSON Key).

Create the restricted Service Account within your project:

```bash
gcloud iam service-accounts create hardening-agent-sa \
    --description="Service account for GCP Hardening Agent" \
    --display-name="GCP Hardening Agent SA" \
    --project=YOUR_PROJECT_ID
```
Replace `YOUR_PROJECT_ID` with your project's ID.

### Resource Permissions (Scoping)

Grant the Service Account the specific IAM roles required. You can choose between creating a custom role for least privilege or using predefined roles if you prefer not to create custom roles.

#### Approach 1: Least Privilege (Recommended)

This approach uses a restricted custom role with minimal BigQuery permissions.

> [!NOTE]
> To create the custom role, the Identity and Access Management (IAM) API (`iam.googleapis.com`) must be enabled on the project.

1. **Create the custom role:**

```bash
# If running from the repository root
gcloud iam roles create hardeningAgentViewer \
    --project=YOUR_PROJECT_ID \
    --file=agent/custom-role-creation/hardening-viewer-role.yaml
```
Replace `YOUR_PROJECT_ID` with your project's ID.

2. **Bind the custom role to the Service Account:**

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:hardening-agent-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="projects/YOUR_PROJECT_ID/roles/hardeningAgentViewer" # pragma: allowlist secret
```

3. **Bind the predefined role for MCP tool usage (required for agent tools):**
```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:hardening-agent-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/mcp.toolUser"
```

#### Approach 2: Predefined Roles (Alternative)

If you prefer not to create custom roles, you can use standard predefined roles. Note that this grants broader permissions than the custom role.

1. **Bind the BigQuery User role to the Service Account:**

```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:hardening-agent-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/bigquery.user"
```

2. **Bind the predefined role for MCP tool usage (required for agent tools):**
```bash
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:hardening-agent-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/mcp.toolUser"
```
## Role & Expertise

The Hardening Agent acts as a professional security peer, providing:

- **Posture Interpretation**: Analyzing Cloud Asset Inventory (CAI) data and security telemetry stored in BigQuery to identify vulnerabilities.
- **Consultative Hardening**: Asking the user about specific hardening requirements and constraints.
- **Blueprint Generation**: Designing new, custom Terraform blueprints (e.g., `ght-agent-generated-blueprint`) by leveraging the toolkit's stateless modules.

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
