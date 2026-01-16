# GCP Foundation - Security Command Center (SCC)

This module provides Bash scripts to programmatically enable Security Command Center (SCC) services and configure Security Health Analytics (SHA) modules for your Google Cloud Organization. It is designed to rapidly bootstrap SCC settings for security research, testing, or hardening engagements.

## Features

- **Enable SCC Services**: Bulk enablement of SCC Premium/Standard services.
- **Configure SHA Modules**: Granular activation of specific Security Health Analytics detection modules (e.g., CMEK, password policies).

## Prerequisites

- **Google Cloud SDK (`gcloud`)**: Must be installed and authenticated.
- **Permissions**:
  - `Organization Admin` or `Security Center Admin` roles on the Organization.
- **Billing Project**: A project linked to a billing account to be used as the quota project for API calls.

## Usage

This module consists of standalone Bash scripts. You must configure the `ORGANIZATION_ID` and `QUOTA_PROJECT` variables inside each script before running them.

### 1. Enable SCC Services

The `enable_scc_services.sh` script enables various SCC detection services.

**Steps:**
1. Open `enable_scc_services.sh`.
2. Update the variables:
   ```bash
   ORGANIZATION_ID="YOUR_ORGANIZATION_ID"
   QUOTA_PROJECT="YOUR_QUOTA_PROJECT"
   ```
3. (Optional) Review the `SCC_SERVICES` array to add or remove services.
4. Run the script:
   ```bash
   ./enable_scc_services.sh
   ```

**Supported Services (Default):**
- `event-threat-detection`
- `security-health-analytics`
- `web-security-scanner`
- `container-threat-detection`
- `virtual-machine-threat-detection`

### 2. Configure SHA Modules

The `enable_sha_modules.sh` script enables specific Security Health Analytics modules.

**Steps:**
1. Open `enable_sha_modules.sh`.
2. Update the variables:
   ```bash
   ORGANIZATION_ID="YOUR_ORGANIZATION_ID"
   QUOTA_PROJECT="YOUR_QUOTA_PROJECT"
   ```
3. (Optional) Review the `SHA_MODULES` array to customize the modules to be enabled.
4. Run the script:
   ```bash
   ./enable_sha_modules.sh
   ```

**Example Modules:**
- `BUCKET_CMEK_DISABLED`
- `SQL_NO_ROOT_PASSWORD`
- `VPC_FLOW_LOGS_SETTINGS_NOT_RECOMMENDED`
- `BIGQUERY_TABLE_CMEK_DISABLED`

## Inputs

| Name | Type | Description |
|------|------|-------------|
| `ORGANIZATION_ID` | String | The ID of the Google Cloud Organization. |
| `QUOTA_PROJECT` | String | The project ID used for API quota and billing. |

## Outputs

Script execution logs to `stdout`, indicating the status of each service or module enablement.
