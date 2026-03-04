import os
from google.adk.agents import LlmAgent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

project_id = os.environ.get("GCP_PROJECT_ID", "YOUR_PROJECT_ID")
org_id = os.environ.get("GCP_ORGANIZATION_ID", "YOUR_ORG_ID")
model = os.environ.get("GOOGLE_MODEL", "YOUR_GEMINI_MODEL")

root_agent = LlmAgent(
    model=model,
    name='scc_security_analyst',
    instruction=(
        'You are a specialized Google Cloud Security expert. '
        'Use the Security Command Center (SCC) tools to list findings, '
        'analyze vulnerabilities, and provide remediation guidance. '
        f'Call top_vulnerability_findings({project_id}, 10) and provide remediation guidance.'
    ),
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="python",
                    args=["-m", "scc_mcp"], 
                    env={
                        **os.environ,
                        "GCP_PROJECT_ID": project_id,
                        "GCP_ORGANIZATION_ID": org_id,
                    }
                ),
            ),
        )
    ],
)