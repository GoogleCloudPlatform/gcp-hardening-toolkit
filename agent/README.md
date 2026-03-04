# GCP Hardening Agent

A specialized security analyst agent powered by the Google ADK (Agent Development Kit). This agent is designed to interact with [Security Command Center (SCC) MCP Server](https://google.github.io/mcp-security/servers/scc_mcp.html) to identify, analyze, and provide remediation guidance for security findings.

## Overview

The `scc_security_analyst` leverages the SCC MCP server. It can:
- List top vulnerability findings and misconfigurations.
- Analyze security risks.
- Provide actionable remediation steps.

## Setup

1. **Install Dependencies**:
   This project uses [uv](https://docs.astral.sh/uv/getting-started/installation/) for dependency management. Install the required packages:
   ```bash
   cd agent
   uv sync
   ```

2. **Environment Variables**:
   Create a `.env` file in `agent/hardening_agent/` with the following variables:

| Variable | Description | Example |
| :--- | :--- | :--- |
| `GCP_PROJECT_ID` | Your Google Cloud Project ID | `my-project-id` |
| `GCP_ORGANIZATION_ID` | Your GCP Organization ID | `123456789012` |
| `GOOGLE_MODEL` | The Gemini model to use | `gemini-2.5-flash` |
| `GOOGLE_GENAI_USE_VERTEXAI` | Set to `1` to use Vertex AI | `1` |

3. **Local Library Modifications**:
   > [!NOTE]
   > This project uses a locally modified version of the `scc-mcp` library. The following changes have been applied to `agent/.venv/lib/python3.13/site-packages/scc_mcp.py`:

   - **API Version**: Updated to use `securitycenter_v2` for enhanced features ([Reference PR #232](https://github.com/google/mcp-security/pull/232)).
   - **Finding Filter**: Expanded to include both `VULNERABILITY` and `MISCONFIGURATION` findings in `top_vulnerability_findings`.
     ```python
     # Original:
     # filter_str = 'state="ACTIVE" AND findingClass="VULNERABILITY" AND (severity="HIGH" OR severity="CRITICAL")'
     # Modified:
     filter_str = 'state="ACTIVE" AND (findingClass="VULNERABILITY" OR findingClass="MISCONFIGURATION") AND (severity="HIGH" OR severity="CRITICAL")'
     ```

## Execution

To run the agent using the ADK CLI:

```bash
cd agent
adk run hardening_agent
```

To run the agent using the ADK Web interface:

```bash
cd agent
adk web
```