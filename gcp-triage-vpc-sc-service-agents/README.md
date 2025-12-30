# VPC-SC Service Agent Authorization Automation

This document outlines a repeatable process for identifying and authorizing Google Cloud Service Agents that are causing VPC Service Controls (VPC-SC) violations. This allows for incremental and audited changes to your service perimeters.

## Prerequisites

* Google Cloud SDK (`gcloud`) installed and authenticated.
* Terraform installed.

## Process

The process involves generating a list of service accounts causing violations, filtering them to create an allowlist, and then applying the changes via Terraform.

### 1. Identify VPC-SC Violations

Run the `get_vpc_sc_violations.sh` script to fetch the latest VPC-SC violations from your perimeter.

```bash
./get_vpc_sc_violations.sh <PERIMETER_NAME>
```

This script will generate two files:

* `vpc_sc_violations.json`: A raw JSON output of all violations within the specified perimeter. This is kept for auditing and potential future enhancements.
* `vpc_sc_violations_sa.txt`: A text file containing a simple list of the unique service accounts that caused the violations.

### 2. Filter and Create Allowlist

Next, you need to filter the `vpc_sc_violations_sa.txt` to create a curated list of service accounts that you want to authorize.

**Quick Start: Standard Trusted Agents**

Google-managed Service Agents have unique IDs specific to your project (e.g., `service-12345@container-engine-robot...`). You can run the following block to automatically find these common infrastructure agents in your violations file and add their full emails to your allowlist:

```bash
# Add GKE Service Agent
grep "container-engine-robot.iam.gserviceaccount.com" vpc_sc_violations_sa.txt >> authorized_sa_list.txt

# Add App Engine Service Agent
grep "gae-api-prod.google.com.iam.gserviceaccount.com" vpc_sc_violations_sa.txt >> authorized_sa_list.txt

# Add Vertex AI (AI Platform) Service Agent
grep "gcp-sa-aiplatform-cc.iam.gserviceaccount.com" vpc_sc_violations_sa.txt >> authorized_sa_list.txt

# Add Cloud Batch Service Agent
grep "gcp-sa-cloudbatch.iam.gserviceaccount.com" vpc_sc_violations_sa.txt >> authorized_sa_list.txt

# Add Dialogflow Service Agent
grep "gcp-sa-dialogflow.iam.gserviceaccount.com" vpc_sc_violations_sa.txt >> authorized_sa_list.txt

# Add Cloud Workstations Service Agent
grep "gcp-sa-workstationsvm.iam.gserviceaccount.com" vpc_sc_violations_sa.txt >> authorized_sa_list.txt

# Add Dataproc Service Agent
grep "dataproc-accounts.iam.gserviceaccount.com" vpc_sc_violations_sa.txt >> authorized_sa_list.txt
```

**Example: Authorizing the Web Security Scanner**

To authorize a specific service agent, like the Web Security Scanner, you can `grep` for its domain and append it to your allowlist file (`authorized_sa_list.txt`).

```bash
grep "gcp-sa-websecurityscanner.iam.gserviceaccount.com" vpc_sc_violations_sa.txt >> authorized_sa_list.txt
```

**Example: Removing Service Accounts from the Allowlist**

If you need to remove a group of service accounts from your allowlist, you can use `grep -v`.

```bash
grep -v "unwanted-domain.com" authorized_sa_list.txt > temp_list.txt && mv temp_list.txt authorized_sa_list.txt
```

### 3. Verify and Apply Changes

Once you have updated your `authorized_sa_list.txt`, you can use Terraform to preview and apply the changes to your VPC-SC perimeter.

1.  **Preview the changes:**
    ```bash
    terraform plan
    ```
    This command will show you which service accounts will be added to the **Ingress/Egress policies**.

2.  **Apply the changes:**
    ```bash
    terraform apply
    ```
    This will authorize the service accounts in your `authorized_sa_list.txt`.

### 4. Important: Managing Existing Perimeters

**Script Usage:**
The `get_vpc_sc_violations.sh` script is standalone and works with **any** existing VPC Service Controls perimeter in your organization. You do not need to use the provided Terraform code to use the script.

**Terraform Code:**
The included Terraform files (`main.tf`, `vpc_sc.tf`) serve as a **reference implementation**. They demonstrate how to:
1.  Structure a perimeter with `ingress_policies` and `egress_policies`.
2.  Dynamically inject the authorized service account list.
3.  Target the **Dry Run** (`spec`) configuration for safe testing.

If you already have a Terraform pipeline for your perimeters, you should adapt the logic from `vpc_sc.tf` (specifically the `locals` block and the `ingress_policies` / `egress_policies` sections) into your existing codebase. The provided `vpc_sc.tf` applies changes to the **Dry Run** config; you must promote these to the Enforced config (`status`) when ready.

## Security Considerations

### Strategy: Ingress/Egress vs. Access Levels
This automation implements a "Least Privilege" security model. We explicitly **avoid** using Access Levels for Service Agents.

* ❌ **Access Levels (Anti-Pattern):** Adding a Service Agent to an Access Level grants it a "Global Bypass." If the agent is compromised (e.g., via a confused deputy attack), it can exfiltrate data to **any** location (public internet, personal Gmail), rendering the perimeter useless.
* ✅ **Ingress/Egress Rules (Implemented):** This project adds agents to `ingress_policies` and `egress_policies`. This acts as a specific "Keycard." The agent is allowed to enter the perimeter to perform its job and is allowed to Egress *only* to Google APIs. It cannot bypass the perimeter to reach unauthorized external networks.

### Triage Matrix
Use this table to decide if a blocked agent should be added to the allowlist:

| Category | Examples | Risk Level | Action |
| :--- | :--- | :--- | :--- |
| **Infrastructure Robots** | `container-engine-robot`, `gae-api-prod`, `cloud-build` | **Low (Managed)** | **✅ Allow.** Required for the service to function (scaling, deploying). |
| **Telemetry Agents** | `gcp-sa-logging`, `gcp-sa-monitoring` | **Low** | **✅ Allow.** Blocking these causes observability blind spots. |
| **Compute/AI Agents** | `gcp-sa-aiplatform`, `gcp-sa-notebooks` | **Medium** | **⚠️ Review.** These act on behalf of user code. Safe with Ingress Rules, but ensure they are not User-Managed identities. |
| **Default SAs** | `[project-id]-compute@...` | **High** | **❌ DENY.** These are user-accessible keys. Do not add to the global list. |
| **User-Created SAs** | `my-custom-app@...` | **High** | **❌ DENY.** Create specific, granular rules for these instead. |

Please review Google Cloud's [Service agents documentation](https://docs.cloud.google.com/iam/docs/service-agents) to ensure that the roles and permissions of the service agents are acceptable within your security perimeter.

## File Descriptions

This repository contains the following key files:

* `main.tf`: This Terraform file is designed to deploy a test environment, including resources that intentionally generate VPC Service Controls (VPC-SC) violations. This setup is crucial for testing the `get_vpc_sc_violations.sh` script. **Note:** You will need to modify this file to align with the specific requirements and resources of your test environment.
* `vpc_sc.tf`: This Terraform file contains the core configuration for VPC Service Controls. It implements the logic to apply **Ingress and Egress rules** (rather than Access Levels) based on the authorized list.
* `get_vpc_sc_violations.sh`: A shell script used to fetch and process VPC-SC violations from your Google Cloud perimeter. It generates `vpc_sc_violations.json` and `vpc_sc_violations_sa.txt`.
* `vpc_sc_violations.json`: (Generated) A raw JSON output containing all detected VPC-SC violations within the specified perimeter. This file is retained for auditing purposes and potential future analysis.
* `vpc_sc_violations_sa.txt`: (Generated) A plain text file listing unique service accounts that have caused VPC-SC violations. This file is used as input for filtering and creating your allowlist.
* `authorized_sa_list.txt`: (User-managed) This file is where you curate the list of service accounts that you intend to authorize within your VPC-SC perimeter.
* `terraform.tfvars.example`: An example Terraform variables file. Copy this to `terraform.tfvars` and populate it with your specific project details.
* `variables.tf`: Defines the input variables for the Terraform configurations.